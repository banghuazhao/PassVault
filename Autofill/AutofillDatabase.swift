//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//
// Read-only SQLite access from the Credential Provider extension. Keep schema migrations aligned with `PassVault/Database/AppDatabase.swift`.

import Foundation
import GRDB

enum AutofillDatabase {

  nonisolated static func makeDatabaseQueue() throws -> DatabaseQueue {
    let fm = FileManager.default
    guard let groupRoot = fm.containerURL(forSecurityApplicationGroupIdentifier: PassVaultAppGroup.identifier)
    else {
      throw AutofillDatabaseError.missingSharedContainer
    }
    let dir = groupRoot.appending(component: "PassVault", directoryHint: .isDirectory)
    try fm.createDirectory(at: dir, withIntermediateDirectories: true)
    let url = dir.appending(path: "vault.sqlite")

    var configuration = Configuration()
    configuration.foreignKeysEnabled = true
    let dbPath = url.path(percentEncoded: false)
    let queue = try DatabaseQueue(path: dbPath, configuration: configuration)

    var migrator = DatabaseMigrator()

    migrator.registerMigration("v1-bootstrap") { db in
      try Self.bootstrapSchema(db: db)
    }

    try migrator.migrate(queue)
    return queue
  }

  nonisolated private static func bootstrapSchema(db: Database) throws {
    try db.execute(
      sql: """
      CREATE TABLE IF NOT EXISTS "categories" (
        "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        "name" TEXT NOT NULL,
        "iconSFName" TEXT NOT NULL DEFAULT 'folder.fill',
        "sortOrder" INTEGER NOT NULL DEFAULT 0
      ) STRICT
      """
    )

    try db.execute(
      sql: """
      CREATE TABLE IF NOT EXISTS "vaultPasswords" (
        "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        "categoryId" INTEGER NOT NULL,
        "title" TEXT NOT NULL DEFAULT '',
        "passwordBlob" BLOB NOT NULL,
        "reuseFingerprint" TEXT NOT NULL DEFAULT '',
        "entryKindRaw" TEXT NOT NULL DEFAULT 'login',
        "website" TEXT NOT NULL DEFAULT '',
        "notes" TEXT NOT NULL DEFAULT '',
        "customIconSFName" TEXT,
        "reminderIntervalMonths" INTEGER,
        "reminderNextDue" TEXT,
        "tapCount" INTEGER NOT NULL DEFAULT 0,
        "lastOpenedAt" TEXT,
        "createdAt" TEXT NOT NULL,
        "updatedAt" TEXT NOT NULL,

        FOREIGN KEY("categoryId") REFERENCES "categories"("id") ON DELETE RESTRICT ON UPDATE CASCADE
      ) STRICT
      """
    )

    let count = try Int.fetchOne(db, sql: #"SELECT COUNT(*) FROM "categories""#) ?? 0
    guard count == 0 else { return }

    let defaults: [(name: String, icon: String, order: Int)] = [
      ("Personal", "person.fill", 0),
      ("Work", "briefcase.fill", 1),
      ("Family", "figure.2.and.child.holdinghands", 2),
      ("Gaming", "gamecontroller.fill", 3),
      ("Trash", "trash.fill", 9_999),
    ]
    for d in defaults {
      try db.execute(
        sql: """
        INSERT INTO "categories" ("name", "iconSFName", "sortOrder") VALUES (?, ?, ?)
        """,
        arguments: [d.name, d.icon, d.order],
      )
    }
  }

  nonisolated static func fetchPasswordRows(forMatchingHosts hosts: Set<String>) throws -> [AutofillStoredPasswordRow] {
    let queue = try makeDatabaseQueue()
    return try queue.read { db in
      let rows =
        try AutofillStoredPasswordRow.fetchAll(
          db,
          sql: #"SELECT id, title, passwordBlob, website FROM "vaultPasswords" ORDER BY title COLLATE NOCASE"#)

      if hosts.isEmpty {
        return rows.map {
          AutofillStoredPasswordRow(
            id: $0.id,
            title: $0.title,
            passwordBlob: $0.passwordBlob,
            website: $0.website,
            isLikelyMatch: false,
          )
        }
      }

      return rows.map { row in
        AutofillStoredPasswordRow(
          id: row.id,
          title: row.title,
          passwordBlob: row.passwordBlob,
          website: row.website,
          isLikelyMatch: AutofillWebsiteHostMatch.matches(hosts: hosts, website: row.website),
        )
      }
      .sorted { lhs, rhs in
        switch (lhs.isLikelyMatch, rhs.isLikelyMatch) {
        case (true, false): return true
        case (false, true): return false
        default: return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
      }
    }
  }

  nonisolated static func fetchCategories() throws -> [AutofillCategoryRow] {
    let queue = try makeDatabaseQueue()
    return try queue.read { db in
      try AutofillCategoryRow.fetchAll(db, sql: #"SELECT id, name FROM "categories" ORDER BY sortOrder"#)
    }
  }

  nonisolated static func insertPassword(
    categoryId: Int64,
    title: String,
    password: String,
    website: String,
    notes: String,
    customIconSFName: String?,
    reminderMonths: Int?
  ) throws {
    let queue = try makeDatabaseQueue()
    let now = Date()
    let formatter = ISO8601DateFormatter()
    let dateString = formatter.string(from: now)

    let blob = try AutofillVaultCrypto.seal(Data(password.utf8))
    let fingerprint = AutofillVaultCrypto.fingerprint(for: password)

    try queue.write { db in
      try db.execute(
        sql: """
          INSERT INTO "vaultPasswords" (
            "categoryId", "title", "passwordBlob", "reuseFingerprint",
            "entryKindRaw", "website", "notes", "customIconSFName",
            "reminderIntervalMonths", "tapCount", "createdAt", "updatedAt"
          ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
          """,
        arguments: [
          categoryId, title, blob, fingerprint,
          "login", website, notes, customIconSFName,
          reminderMonths, 0, dateString, dateString,
        ]
      )
    }
  }
}

nonisolated enum AutofillDatabaseError: Error {
  case missingSharedContainer
}

nonisolated struct AutofillStoredPasswordRow: FetchableRecord {
  let id: Int64
  let title: String
  let passwordBlob: Data
  let website: String
  let isLikelyMatch: Bool

  init(row: GRDB.Row) throws {
    id = row["id"]
    title = row["title"]
    passwordBlob = row["passwordBlob"]
    website = row["website"]
    isLikelyMatch = false
  }

  init(id: Int64, title: String, passwordBlob: Data, website: String, isLikelyMatch: Bool) {
    self.id = id
    self.title = title
    self.passwordBlob = passwordBlob
    self.website = website
    self.isLikelyMatch = isLikelyMatch
  }
}

nonisolated struct AutofillCategoryRow: FetchableRecord, Identifiable, Hashable {
  let id: Int64
  let name: String

  init(row: GRDB.Row) throws {
    id = row["id"]
    name = row["name"]
  }
}

nonisolated enum AutofillWebsiteHostMatch {

  nonisolated static func matches(hosts: Set<String>, website: String) -> Bool {
    let w = website.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard w.isEmpty == false else { return false }
    for h in hosts {
      if let u = URL(string: w), let wh = u.host?.lowercased(), wh == h || wh.hasSuffix("." + h) {
        return true
      }
      if let prefixed = URL(string: "https://\(w)"), let wh = prefixed.host?.lowercased(), wh == h || wh.hasSuffix("." + h) {
        return true
      }
      if w.contains(h) {
        return true
      }
    }
    return false
  }
}
