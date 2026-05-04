//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

nonisolated enum VaultSecrets {

  nonisolated static func plaintext(from row: VaultPasswordRow) throws -> String {
    let data = try VaultCrypto.open(row.passwordBlob)
    return String(decoding: data, as: UTF8.self)
  }

  nonisolated static func seal(password: String) throws -> Data {
    try VaultCrypto.seal(Data(password.utf8))
  }

  nonisolated static func fingerprint(for password: String) -> String {
    VaultCryptoFingerprint.sha256Hex(ofUtf8Password: password)
  }
}

nonisolated enum PasswordRotationPlanning {
  nonisolated static func nextDueDate(from baseline: Date, months: Int?) -> Date? {
    guard let months, months > 0 else { return nil }
    return Calendar.current.date(byAdding: .month, value: months, to: baseline)
  }
}
