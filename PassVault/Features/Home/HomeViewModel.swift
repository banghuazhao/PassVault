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
final class HomeViewModel {

  enum SortMode: Hashable {
    case nameAscending
    case nameDescending
    case dateDescending
    case dateAscending
  }

  @ObservationIgnored @FetchAll(VaultPasswordRow.all) private var fetchedPasswords: [VaultPasswordRow]
  @ObservationIgnored @FetchAll(CategoryRow.order(by: \.sortOrder)) var categories: [CategoryRow]
  @ObservationIgnored @Dependency(\.defaultDatabase) private var database

  /// Full vault list (SQLiteData-managed); mirrors the backing fetch ordered by persistence defaults.
  var allVaultRows: [VaultPasswordRow] {
    fetchedPasswords
  }

  var sortMode: SortMode = .nameAscending
  var searchQuery: String = ""
  /// `nil` means “All”; otherwise filters to the category identifier.
  var selectedCategoryFilter: Int?
  var lastErrorDescription: String?

  init() {}

  func clearError() {
    lastErrorDescription = nil
  }

  /// Aligns pending local notifications with `allVaultRows` (after login, DB sync, etc.).
  func syncScheduledPasswordReminders() async {
    await PasswordReminderScheduler.rescheduleAll(rows: allVaultRows)
  }

  var isSearching: Bool {
    !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  var displayedPasswords: [VaultPasswordRow] {
    var rows = fetchedPasswords
    if let filter = selectedCategoryFilter {
      rows = rows.filter { $0.categoryId == filter }
    }
    let trimmed = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    if !trimmed.isEmpty {
      rows = rows.filter {
        $0.title.lowercased().contains(trimmed)
          || $0.website.lowercased().contains(trimmed)
          || $0.notes.lowercased().contains(trimmed)
      }
    }
    switch sortMode {
    case .nameAscending:
      rows.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    case .nameDescending:
      rows.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedDescending }
    case .dateDescending:
      rows.sort { $0.updatedAt > $1.updatedAt }
    case .dateAscending:
      rows.sort { $0.updatedAt < $1.updatedAt }
    }
    return rows
  }

  func plaintext(for row: VaultPasswordRow) -> String {
    do {
      return try VaultSecrets.plaintext(from: row)
    } catch {
      lastErrorDescription = error.localizedDescription
      return ""
    }
  }

  func decryptAllForExport() throws -> [(row: VaultPasswordRow, categoryName: String, password: String)] {
    let map = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0.name) })
    return try fetchedPasswords.map { row throws in
      let name = map[row.categoryId] ?? ""
      let password = try VaultSecrets.plaintext(from: row)
      return (row, name, password)
    }
  }

  func recordAccess(_ row: VaultPasswordRow) async {
    do {
      var next = row
      next.tapCount += 1
      next.lastOpenedAt = Date()

      try await database.write { db in
        try VaultPasswordRow.update(next).execute(db)
      }
    } catch {
      lastErrorDescription = error.localizedDescription
    }
  }

  @discardableResult
  func insertPassword(
    categoryId: Int,
    title: String,
    password: String,
    entryKindRaw: String,
    website: String,
    notes: String,
    customIconSFName: String?,
    reminderMonths: Int?
  )
    async -> VaultPasswordRow?
  {
    let now = Date()
    do {
      let fingerprint = VaultSecrets.fingerprint(for: password)
      let blob = try VaultSecrets.seal(password: password)

      try await database.write { db in
        let draft = VaultPasswordRow.Draft(
          categoryId: categoryId,
          title: title,
          passwordBlob: blob,
          reuseFingerprint: fingerprint,
          entryKindRaw: entryKindRaw,
          website: website,
          notes: notes,
          customIconSFName: customIconSFName,
          reminderIntervalMonths: reminderMonths,
          reminderNextDue: PasswordRotationPlanning.nextDueDate(from: now, months: reminderMonths),
          tapCount: 0,
          lastOpenedAt: nil as Date?,
          createdAt: now,
          updatedAt: now,
        )
        _ = try VaultPasswordRow.insert { draft }.execute(db)
      }

      let insertedId = try await database.read { db in
        try Int.fetchOne(db, sql: "SELECT last_insert_rowid()")
      }

      guard let insertedId else { return nil }

      guard
        let inserted = try await database.read({ db in
          try VaultPasswordRow.where { $0.id.eq(insertedId) }.fetchOne(db)
        })
      else {
        return nil
      }

      await PasswordReminderScheduler.reschedule(row: inserted)
      return inserted
    } catch {
      lastErrorDescription = error.localizedDescription
      return nil
    }
  }

  @discardableResult
  func updatePassword(
    _ row: VaultPasswordRow,
    categoryId: Int,
    title: String,
    password: String?,
    entryKindRaw: String,
    website: String,
    notes: String,
    customIconSFName: String?,
    reminderMonths: Int?
  )
    async -> VaultPasswordRow?
  {
    var next = row
    next.categoryId = categoryId
    next.title = title
    next.entryKindRaw = entryKindRaw
    next.website = website
    next.notes = notes
    next.customIconSFName = customIconSFName

    next.reminderIntervalMonths = reminderMonths
    next.reminderNextDue = PasswordRotationPlanning.nextDueDate(from: Date(), months: reminderMonths)
    next.updatedAt = Date()

    if let password, !password.isEmpty {
      do {
        next.passwordBlob = try VaultSecrets.seal(password: password)
        next.reuseFingerprint = VaultSecrets.fingerprint(for: password)
      } catch {
        lastErrorDescription = error.localizedDescription
        return nil
      }
    }

    do {
      try await database.write { db in
        try VaultPasswordRow.update(next).execute(db)
      }
      await PasswordReminderScheduler.reschedule(row: next)
      return next
    } catch {
      lastErrorDescription = error.localizedDescription
      return nil
    }
  }

  func deletePassword(_ row: VaultPasswordRow) async {
    PasswordReminderScheduler.cancel(entryId: row.id)
    do {
      try await database.write { db in
        try VaultPasswordRow.delete(row).execute(db)
      }
    } catch {
      lastErrorDescription = error.localizedDescription
    }
  }

  func importRecords(
    records: [PassVaultExportRecord],
    defaultCategoryId: Int?
  )
    async
  {
    guard let fallback =
      defaultCategoryId
      ?? categories.first?.id else {
      lastErrorDescription = String(localized: "Pick a vault category before importing.")
      return
    }

    for record in records {
      _ =
        await insertPassword(
          categoryId: fallback,
          title: record.title,
          password: record.password,
          entryKindRaw: record.entryKindRaw,
          website: record.website,
          notes: record.notes,
          customIconSFName: nil,
          reminderMonths: nil,
        )
    }
  }

  func deleteAllPasswords() async {
    let snapshot = fetchedPasswords
    for row in snapshot {
      PasswordReminderScheduler.cancel(entryId: row.id)
    }

    do {
      try await database.write { db in
        for row in try VaultPasswordRow.all.fetchAll(db) {
          try VaultPasswordRow.delete(row).execute(db)
        }
      }
    } catch {
      lastErrorDescription = error.localizedDescription
    }
  }

  func categoryName(for id: Int?) -> String? {
    guard let id else { return nil }
    return categories.first { $0.id == id }?.name
  }

  /// Latest row from the vault store (stable `id` for navigation — row structs change when taps/reminders update).
  func passwordRow(withId id: Int) -> VaultPasswordRow? {
    allVaultRows.first { $0.id == id }
  }

  func exportArchive() throws -> Data {
    try PassVaultImportExportService.exportJSON(entries: decryptAllForExport())
  }
}
