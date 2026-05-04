//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Dependencies
import Foundation
import GRDB
import Observation
import SQLiteData

@Observable
@MainActor
final class CategoriesViewModel {

  @ObservationIgnored @FetchAll(CategoryRow.order(by: \.sortOrder)) private var fetchedCategories:
    [CategoryRow]
  @ObservationIgnored @FetchAll(VaultPasswordRow.all) private var passwords: [VaultPasswordRow]

  @ObservationIgnored @Dependency(\.defaultDatabase) private var database

  var categories: [CategoryRow] {
    fetchedCategories
  }

  var lastErrorDescription: String?

  init() {}

  func passwordCount(for categoryId: Int) -> Int {
    passwords.filter { $0.categoryId == categoryId }.count
  }

  func insertCategory(name: String, iconSFName: String) async {
    do {
      let nextOrder =
        (try await database.read { db in
          try Int.fetchOne(db, sql: """
            SELECT COALESCE(MAX("sortOrder"), -1) FROM "categories"
            """)
        } ?? -1) + 1

      try await database.write { db in
        try CategoryRow.insert {
          CategoryRow.Draft(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            iconSFName: iconSFName,
            sortOrder: nextOrder,
          )
        }.execute(db)
      }
    } catch {
      lastErrorDescription = error.localizedDescription
    }
  }

  func updateCategory(name: String, iconSFName: String, for row: CategoryRow) async {
    var next = row
    next.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
    next.iconSFName = iconSFName
    await persistCategory(next)
  }

  func persistCategory(_ next: CategoryRow) async {
    do {
      try await database.write { db in
        try CategoryRow.update(next).execute(db)
      }
    } catch {
      lastErrorDescription = error.localizedDescription
    }
  }

  func deleteCategory(_ category: CategoryRow, migratingPasswordsTo destinationId: Int) async {
    do {
      let affectedRows = passwords.filter { $0.categoryId == category.id }
      try await database.write { db in
        for var row in affectedRows {
          row.categoryId = destinationId
          row.updatedAt = Date()
          try VaultPasswordRow.update(row).execute(db)
        }
        try CategoryRow.delete(category).execute(db)
      }
    } catch {
      lastErrorDescription = error.localizedDescription
    }
  }
}
