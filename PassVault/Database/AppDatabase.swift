//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import GRDB
import SQLiteData

enum AppDatabase {

  nonisolated static func makeDatabaseQueue() throws -> DatabaseQueue {
    let fm = FileManager.default
    guard let groupRoot = fm.containerURL(forSecurityApplicationGroupIdentifier: PassVaultAppGroup.identifier)
    else {
      throw AppDatabaseError.missingSharedContainer(
        "Configure the \(PassVaultAppGroup.identifier) App Group on the PassVault target and sign with a provisioning profile that includes it."
      )
    }
    let dir = groupRoot.appending(component: "PassVault", directoryHint: .isDirectory)
    try fm.createDirectory(at: dir, withIntermediateDirectories: true)
    try migrateLegacyDatabaseIfNeeded(fm: fm, groupDirectory: dir)
    let url = dir.appending(path: "vault.sqlite")

    var configuration = Configuration()
    configuration.foreignKeysEnabled = true

    // SQLite expects a POSIX path with real spaces; `path(percentEncoded: true)` leaves `%20` in the string
    // and `open()` fails with SQLITE_CANTOPEN (error 14).
    let dbPath = url.path(percentEncoded: false)
    let queue = try DatabaseQueue(path: dbPath, configuration: configuration)

    var migrator = DatabaseMigrator()

    migrator.registerMigration("v1-bootstrap") { db in
      try #sql(
        """
        CREATE TABLE IF NOT EXISTS "categories" (
          "id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
          "name" TEXT NOT NULL,
          "iconSFName" TEXT NOT NULL DEFAULT 'folder.fill',
          "sortOrder" INTEGER NOT NULL DEFAULT 0
        ) STRICT
        """
      )
      .execute(db)

      try #sql(
        """
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
      .execute(db)

      guard try Int.fetchOne(db, sql: "SELECT COUNT(*) FROM categories") == 0 else { return }

      let defaults: [(name: String, icon: String, order: Int)] = [
        ("Personal", "person.fill", 0),
        ("Work", "briefcase.fill", 1),
        ("Family", "figure.2.and.child.holdinghands", 2),
        ("Gaming", "gamecontroller.fill", 3),
        ("Trash", "trash.fill", 9_999),
      ]
      for d in defaults {
        try CategoryRow.insert {
          CategoryRow.Draft(
            name: d.name,
            iconSFName: d.icon,
            sortOrder: d.order,
          )
        }
        .execute(db)
      }
    }

    try migrator.migrate(queue)
    return queue
  }

  nonisolated private static func migrateLegacyDatabaseIfNeeded(fm: FileManager, groupDirectory: URL) throws {
    let legacyBase =
      try fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
    let legacyDir = legacyBase.appending(component: "PassVault", directoryHint: .isDirectory)
    let newDB = groupDirectory.appending(path: "vault.sqlite")
    guard fm.fileExists(atPath: newDB.path) == false else { return }
    let legacyDB = legacyDir.appending(path: "vault.sqlite")
    guard fm.fileExists(atPath: legacyDB.path) else { return }

    let sidecars = ["vault.sqlite-shm", "vault.sqlite-wal"]
    try fm.createDirectory(at: groupDirectory, withIntermediateDirectories: true)
    try fm.moveItem(at: legacyDB, to: newDB)
    for name in sidecars {
      let legacyExtra = legacyDir.appending(path: name)
      guard fm.fileExists(atPath: legacyExtra.path) else { continue }
      let dest = groupDirectory.appending(path: name)
      if fm.fileExists(atPath: dest.path) {
        try fm.removeItem(at: dest)
      }
      try fm.moveItem(at: legacyExtra, to: dest)
    }
  }
}

nonisolated enum AppDatabaseError: LocalizedError {
  case missingSharedContainer(String)

  var errorDescription: String? {
    switch self {
    case .missingSharedContainer(let detail):
      return detail
    }
  }
}
