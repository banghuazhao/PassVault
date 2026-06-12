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

  // MARK: - JSON (Bitwarden Compatible)

  nonisolated static func exportJSON(
    entries: [(row: VaultPasswordRow, categoryName: String, password: String)]
  ) throws -> Data {
    let categoryNames = Set(entries.map { $0.categoryName })
    let folders: [BitwardenFolder] = categoryNames.map { BitwardenFolder(id: UUID(), name: $0) }
    
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

  // MARK: - CSV (Chrome/Safari/Industry Standard)

  nonisolated static func exportCSV(
    entries: [(row: VaultPasswordRow, categoryName: String, password: String)]
  ) -> Data {
    var csv = "title,url,username,password,folder,notes\n"
    for pair in entries {
        let title = escapeCSV(pair.row.title)
        let url = escapeCSV(pair.row.website)
        let username = escapeCSV(pair.row.title) // PassVault uses Title as primary label
        let password = escapeCSV(pair.password)
        let folder = escapeCSV(pair.categoryName)
        let notes = escapeCSV(pair.row.notes)
        
        csv += "\(title),\(url),\(username),\(password),\(folder),\(notes)\n"
    }
    return Data(csv.utf8)
  }

  nonisolated static func decodeCSV(data: Data) -> [ImportedRecord] {
    guard let content = String(data: data, encoding: .utf8) else { return [] }
    let lines = content.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    guard lines.count > 1 else { return [] }
    
    let headerRow = parseCSVLine(lines[0])
    let headerMap = mapHeaders(headerRow)
    
    return lines.dropFirst().compactMap { line in
        let columns = parseCSVLine(line)
        guard columns.count > 0 else { return nil }
        
        func col(_ keys: [String]) -> String {
            for key in keys {
                if let idx = headerMap[key], idx < columns.count {
                    return columns[idx]
                }
            }
            return ""
        }
        
        let title = col(["title", "name"])
        let url = col(["url", "website", "uri", "login_uri"])
        let password = col(["password", "login_password"])
        let notes = col(["notes", "note", "extra"])
        let folder = col(["folder", "grouping", "category"])
        
        if title.isEmpty && url.isEmpty && password.isEmpty { return nil }
        
        return ImportedRecord(
            title: title.isEmpty ? url : title,
            password: password,
            website: url,
            notes: notes,
            categoryName: folder.isEmpty ? nil : folder
        )
    }
  }

  private static func mapHeaders(_ headers: [String]) -> [String: Int] {
    var map: [String: Int] = [:]
    for (idx, header) in headers.enumerated() {
        map[header.lowercased().trimmingCharacters(in: .whitespaces)] = idx
    }
    return map
  }

  private static func parseCSVLine(_ line: String) -> [String] {
    var columns: [String] = []
    var current = ""
    var inQuotes = false
    
    let chars = Array(line)
    var i = 0
    while i < chars.count {
        let char = chars[i]
        if char == "\"" {
            if inQuotes && i + 1 < chars.count && chars[i+1] == "\"" {
                // Escaped quote
                current.append("\"")
                i += 1
            } else {
                inQuotes.toggle()
            }
        } else if char == "," && !inQuotes {
            columns.append(current.trimmingCharacters(in: .whitespaces))
            current = ""
        } else {
            current.append(char)
        }
        i += 1
    }
    columns.append(current.trimmingCharacters(in: .whitespaces))
    return columns
  }

  private static func escapeCSV(_ text: String) -> String {
    if text.contains(",") || text.contains("\"") || text.contains("\n") {
        let escaped = text.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }
    return text
  }
}

struct ImportedRecord {
  let title: String
  let password: String
  let website: String
  let notes: String
  let categoryName: String?
}
