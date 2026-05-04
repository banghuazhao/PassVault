//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

struct PassVaultExportEnvelope: Codable, Sendable {
  var version = 1
  var exportedAt: Date
  var entries: [PassVaultExportRecord]
}

nonisolated struct PassVaultExportRecord: Codable, Hashable, Sendable {
  var title: String
  var password: String
  var entryKindRaw: String
  var website: String
  var notes: String
  var categoryNameSnapshot: String?
  var createdAt: Date
  var updatedAt: Date
}

nonisolated enum PassVaultImportExportService {

  nonisolated static func exportJSON(
    entries: [(row: VaultPasswordRow, categoryName: String, password: String)]
  ) throws -> Data {
    let records: [PassVaultExportRecord] =
      entries.map { pair in
        PassVaultExportRecord(
          title: pair.row.title,
          password: pair.password,
          entryKindRaw: pair.row.entryKindRaw,
          website: pair.row.website,
          notes: pair.row.notes,
          categoryNameSnapshot: pair.categoryName,
          createdAt: pair.row.createdAt,
          updatedAt: pair.row.updatedAt,
        )
      }
    let envelope = PassVaultExportEnvelope(exportedAt: Date(), entries: records)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .iso8601
    return try encoder.encode(envelope)
  }

  nonisolated static func decodeImport(data: Data) throws -> PassVaultImportEnvelope {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let env = try decoder.decode(PassVaultExportEnvelope.self, from: data)
    return PassVaultImportEnvelope(records: env.entries)
  }
}

nonisolated struct PassVaultImportEnvelope {
  var records: [PassVaultExportRecord]
}
