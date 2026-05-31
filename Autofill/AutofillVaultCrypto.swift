//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//
// Mirrors `PassVault/Services/VaultCrypto.swift`; keep cryptographic behavior in sync.

import CryptoKit
import Foundation
import Security

nonisolated enum AutofillVaultCrypto {
  nonisolated private static let account = "vault.aes.passvault"

  nonisolated static func seal(_ password: Data) throws -> Data {
    let sealed = try AES.GCM.seal(password, using: try loadOrMakeKey())
    guard let combine = sealed.combined else {
      throw AutofillVaultCryptoError.missingCombined
    }
    return combine
  }

  nonisolated static func open(_ blob: Data) throws -> Data {
    let box = try AES.GCM.SealedBox(combined: blob)
    return try AES.GCM.open(box, using: try loadOrMakeKey())
  }

  nonisolated static func fingerprint(for password: String) -> String {
    SHA256.hash(data: Data(password.utf8))
      .map { String(format: "%02x", $0) }
      .joined()
  }

  nonisolated private static func loadOrMakeKey() throws -> SymmetricKey {
    let accessGroup = AutofillKeychainConfig.accessGroupRawValue

    if let ag = accessGroup {
      if let saved = AutofillKeychain.shared.read(account: Self.account, accessGroup: ag),
        saved.count == 32
      {
        return SymmetricKey(data: saved)
      }
    } else {
      if let saved = AutofillKeychain.shared.read(account: Self.account, accessGroup: nil),
        saved.count == 32
      {
        return SymmetricKey(data: saved)
      }
    }

    throw AutofillVaultCryptoError.missingKey
  }
}

nonisolated enum AutofillVaultCryptoError: Error {
  case missingKey
  case missingCombined
}

private enum AutofillKeychainConfig {
  nonisolated static var accessGroupRawValue: String? {
    guard let raw = Bundle.main.object(forInfoDictionaryKey: "KeychainAccessGroup") as? String,
      raw.isEmpty == false
    else { return nil }
    return raw
  }
}

private struct AutofillKeychain {
  nonisolated static let shared = AutofillKeychain()

  private let service = "com.appsbay.PassVault.keychain.v1"

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
}
