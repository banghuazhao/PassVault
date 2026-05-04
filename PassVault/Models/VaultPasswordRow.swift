//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import SQLiteData

@Table("vaultPasswords")
nonisolated struct VaultPasswordRow: Identifiable, Hashable {
  let id: Int
  var categoryId: Int
  var title: String
  var passwordBlob: Data
  var reuseFingerprint: String
  var entryKindRaw: String
  var website: String
  var notes: String
  var customIconSFName: String?

  /// Number of calendar months between password refreshes — `nil` when reminders are disabled.
  var reminderIntervalMonths: Int?
  var reminderNextDue: Date?
  var tapCount: Int
  var lastOpenedAt: Date?
  var createdAt: Date
  var updatedAt: Date
}

extension VaultPasswordRow {
  var entryKind: PassVaultEntryKind {
    PassVaultEntryKind(rawValue: entryKindRaw) ?? .login
  }

  /// When the title is all decimal digits, use up to the first two as the list icon (e.g. PIN-style names).
  var numericTitleIconText: String? {
    let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !t.isEmpty else { return nil }
    guard t.allSatisfy(\.isNumber) else { return nil }
    return String(t.prefix(2))
  }
}
