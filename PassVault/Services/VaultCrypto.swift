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
    if let saved = Keychain.shared.read(account: Self.account),
      saved.count == 32
    {
      return SymmetricKey(data: saved)
    }

    var bytes = [UInt8](repeating: 0, count: 32)
    let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
    guard status == errSecSuccess else { throw VaultCryptoError.randomFailure }
    let keyData = Data(bytes)

    try Keychain.shared.store(account: Self.account, data: keyData)
    return SymmetricKey(data: keyData)
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

  nonisolated func read(account: String) -> Data? {
    let query =
      [
        kSecClass: kSecClassGenericPassword,
        kSecAttrService: service as Any,
        kSecAttrAccount: account as Any,
        kSecReturnData: true,
        kSecMatchLimit: kSecMatchLimitOne,
      ] as CFDictionary

    var output: CFTypeRef?
    let status = SecItemCopyMatching(query, &output)
    guard status == errSecSuccess, let data = output as? Data else { return nil }
    return data
  }

  nonisolated func store(account: String, data: Data) throws {
    let query =
      [
        kSecClass: kSecClassGenericPassword,
        kSecAttrService: service as Any,
        kSecAttrAccount: account as Any,
      ] as CFDictionary

    SecItemDelete(query)

    let saveQuery =
      [
        kSecClass: kSecClassGenericPassword,
        kSecAttrService: service as Any,
        kSecAttrAccount: account as Any,
        kSecValueData: data,
        kSecAttrAccessible: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
      ] as CFDictionary

    let status = SecItemAdd(saveQuery, nil)
    guard status == errSecSuccess else { throw VaultCryptoError.keychainFailure(status) }
  }
}
