//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import CryptoKit
import Foundation
import Security

enum VaultCrypto {
  nonisolated private static let account = "vault.aes.passvault"

  /// Encrypts plaintext password stored on-disk.
  nonisolated static func seal(_ password: Data) throws -> Data {
    let sealed = try AES.GCM.seal(password, using: try loadOrMakeKey())
    guard let combine = sealed.combined else {
      throw VaultCryptoError.missingCombined
    }
    return combine
  }

  nonisolated static func open(_ blob: Data) throws -> Data {
    let box = try AES.GCM.SealedBox(combined: blob)
    return try AES.GCM.open(box, using: try loadOrMakeKey())
  }

  nonisolated private static func loadOrMakeKey() throws -> SymmetricKey {
    let accessGroup = VaultKeychainConfig.accessGroupRawValue

    if let ag = accessGroup {
      if let saved = Keychain.shared.read(account: Self.account, accessGroup: ag),
        saved.count == 32
      {
        return SymmetricKey(data: saved)
      }
      // One-time migrate from legacy app-scoped Keychain storage (predates AutoFill extension).
      if let legacy = Keychain.shared.readLegacyAppScoped(account: Self.account),
        legacy.count == 32
      {
        try Keychain.shared.store(account: Self.account, data: legacy, accessGroup: ag)
        Keychain.shared.deleteLegacyAppScoped(account: Self.account)
        return SymmetricKey(data: legacy)
      }
    } else {
      if let saved = Keychain.shared.read(account: Self.account, accessGroup: nil),
        saved.count == 32
      {
        return SymmetricKey(data: saved)
      }
    }

    var bytes = [UInt8](repeating: 0, count: 32)
    let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
    guard status == errSecSuccess else { throw VaultCryptoError.randomFailure }
    let keyData = Data(bytes)

    try Keychain.shared.store(account: Self.account, data: keyData, accessGroup: accessGroup)
    return SymmetricKey(data: keyData)
  }
}

private enum VaultKeychainConfig {
  /// From `INFOPLIST_KEY_KeychainAccessGroup` (typically `$(AppIdentifierPrefix)` + suffix).
  nonisolated static var accessGroupRawValue: String? {
    guard let raw = Bundle.main.object(forInfoDictionaryKey: "KeychainAccessGroup") as? String,
      raw.isEmpty == false
    else { return nil }
    return raw
  }
}

nonisolated enum VaultCryptoFingerprint {
  nonisolated static func sha256Hex(ofUtf8Password password: String) -> String {
    SHA256.hash(data: Data(password.utf8))
      .map { String(format: "%02x", $0) }
      .joined()
  }
}

enum VaultCryptoError: Error {
  case missingCombined
  case randomFailure
  case keychainFailure(OSStatus)
}

private struct Keychain {
  nonisolated static let shared = Keychain()

  private let service = "com.appsbay.PassVault.keychain.v1"

  nonisolated func readLegacyAppScoped(account: String) -> Data? {
    read(account: account, accessGroup: nil)
  }

  nonisolated func read(account: String, accessGroup: String?) -> Data? {
    var query =
      [
        String(kSecClass): kSecClassGenericPassword,
        String(kSecAttrService): service,
        String(kSecAttrAccount): account,
        String(kSecReturnData): true as CFBoolean,
        String(kSecMatchLimit): kSecMatchLimitOne,
      ] as [String: Any]

    if let accessGroup {
      query[String(kSecAttrAccessGroup)] = accessGroup
    }

    var output: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &output)
    guard status == errSecSuccess, let data = output as? Data else { return nil }
    return data
  }

  nonisolated func deleteLegacyAppScoped(account: String) {
    let query =
      [
        String(kSecClass): kSecClassGenericPassword,
        String(kSecAttrService): service,
        String(kSecAttrAccount): account,
      ] as CFDictionary
    SecItemDelete(query)
  }

  nonisolated func store(account: String, data: Data, accessGroup: String?) throws {
    var deleteQuery =
      [
        String(kSecClass): kSecClassGenericPassword,
        String(kSecAttrService): service,
        String(kSecAttrAccount): account,
      ] as [String: Any]

    if let accessGroup {
      deleteQuery[String(kSecAttrAccessGroup)] = accessGroup
    }

    SecItemDelete(deleteQuery as CFDictionary)

    var savePayload: [String: Any] = [
      String(kSecClass): kSecClassGenericPassword,
      String(kSecAttrService): service,
      String(kSecAttrAccount): account,
      String(kSecValueData): data,
      String(kSecAttrAccessible): kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
    ]

    if let accessGroup {
      savePayload[String(kSecAttrAccessGroup)] = accessGroup
    }

    let status = SecItemAdd(savePayload as CFDictionary, nil)
    guard status == errSecSuccess else { throw VaultCryptoError.keychainFailure(status) }
  }
}
