//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

// MARK: - Bitwarden Compatible JSON Schema
// This structure follows the Bitwarden JSON export standard for maximum interoperability.

nonisolated struct PassVaultExportEnvelope: Codable, Sendable {
  var folders: [BitwardenFolder] = []
  var items: [BitwardenItem]
}

nonisolated struct BitwardenFolder: Codable, Sendable {
  let id: UUID?
  let name: String
}

nonisolated struct BitwardenItem: Codable, Sendable {
  let type: Int // 1 for login
  let name: String
  let notes: String?
  let favorite: Bool
  let login: BitwardenLogin?
  let folderId: UUID?
}

nonisolated struct BitwardenLogin: Codable, Sendable {
  let uris: [BitwardenURI]?
  let username: String?
  let password: String?
}

nonisolated struct BitwardenURI: Codable, Sendable {
  let uri: String?
}

// MARK: - Service Implementation

nonisolated enum PassVaultImportExportService {

  nonisolated static func exportJSON(
    entries: [(row: VaultPasswordRow, categoryName: String, password: String)]
  ) throws -> Data {
    // Create folders map
    let categoryNames = Set(entries.map { $0.categoryName })
    let folders: [BitwardenFolder] = categoryNames.map { BitwardenFolder(id: UUID(), name: $0) }
    
    // Explicitly map to non-optional UUIDs for the lookup table
    var folderIdLookup: [String: UUID] = [:]
    for folder in folders {
        if let id = folder.id {
            folderIdLookup[folder.name] = id
        }
    }

    let items: [BitwardenItem] = entries.map { pair in
      BitwardenItem(
        type: 1,
        name: pair.row.title.isEmpty ? pair.row.website : pair.row.title,
        notes: pair.row.notes,
        favorite: false,
        login: BitwardenLogin(
          uris: [BitwardenURI(uri: pair.row.website)],
          username: pair.row.title, 
          password: pair.password
        ),
        folderId: folderIdLookup[pair.categoryName]
      )
    }

    let envelope = PassVaultExportEnvelope(folders: folders, items: items)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    return try encoder.encode(envelope)
  }

  nonisolated static func decodeImport(data: Data) throws -> [ImportedRecord] {
    let decoder = JSONDecoder()
    let envelope = try decoder.decode(PassVaultExportEnvelope.self, from: data)
    
    let folderMap = Dictionary(uniqueKeysWithValues: envelope.folders.compactMap { folder -> (UUID, String)? in
        guard let id = folder.id else { return nil }
        return (id, folder.name)
    })

    return envelope.items.compactMap { item in
      guard let login = item.login else { return nil }
      
      return ImportedRecord(
        title: item.name,
        password: login.password ?? "",
        website: login.uris?.first?.uri ?? "",
        notes: item.notes ?? "",
        categoryName: item.folderId.flatMap { folderMap[$0] }
      )
    }
  }
}

struct ImportedRecord {
  let title: String
  let password: String
  let website: String
  let notes: String
  let categoryName: String?
}
