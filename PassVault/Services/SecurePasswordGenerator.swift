//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import Security

enum SecurePasswordGenerator {
  enum GeneratorError: Error {
    case emptyCharset
  }

  private static let upper = Array("ABCDEFGHJKLMNPQRSTUVWXYZ")
  private static let lower = Array("abcdefghijkmnopqrstuvwxyz")
  private static let digits = Array("23456789")
  /// Omits ambiguous quotes and slashes for easier entry on mobile keyboards.
  private static let symbols = Array("#$%&*+-=?@^~")

  nonisolated static func generate(
    length: Int,
    includeUpper: Bool,
    includeLower: Bool,
    includeDigits: Bool,
    includeSymbols: Bool
  ) throws -> String {
    var pool: [Character] = []

    guard (1 ... 128).contains(length) else { throw GeneratorError.emptyCharset }

    if includeUpper { pool.append(contentsOf: Self.upper) }
    if includeLower { pool.append(contentsOf: Self.lower) }
    if includeDigits { pool.append(contentsOf: Self.digits) }
    if includeSymbols { pool.append(contentsOf: Self.symbols) }

    guard !pool.isEmpty else { throw GeneratorError.emptyCharset }

    var ensured: [Character] = []
    if includeUpper {
      ensured.append(upper.randomSecureElement())
    }
    if includeLower {
      ensured.append(lower.randomSecureElement())
    }
    if includeDigits {
      ensured.append(digits.randomSecureElement())
    }
    if includeSymbols {
      ensured.append(symbols.randomSecureElement())
    }

    guard ensured.count <= length else { throw GeneratorError.emptyCharset }

    var output = ensured
    let remaining = length - output.count

    guard remaining >= 0 else { throw GeneratorError.emptyCharset }

    for _ in 0 ..< remaining {
      output.append(pool.randomSecureElement())
    }

    output.shuffleSecure()
    return String(output)
  }

  /// Space-separated random words for memorable passphrases.
  nonisolated static func generatePassphrase(wordCount: Int) throws -> String {
    guard (3 ... 16).contains(wordCount) else { throw GeneratorError.emptyCharset }
    let list = PassphraseWordPool.words
    guard !list.isEmpty else { throw GeneratorError.emptyCharset }

    var pieces: [String] = []
    pieces.reserveCapacity(wordCount)
    for _ in 0 ..< wordCount {
      let idx = Int(UInt.randomSecure(limit: UInt32(list.count)))
      pieces.append(list[idx])
    }
    return pieces.joined(separator: " ")
  }
}

nonisolated private extension Array where Element == Character {

  func randomSecureElement() -> Character {
    let idxData = UInt.randomSecure(limit: UInt32(count))
    return self[Int(idxData)]
  }
}

nonisolated private extension UInt {
  /// Uniform index in `[0, limit)` via rejection sampling where `limit` divides uniformly into `UInt32.max`.
  static func randomSecure(limit: UInt32) -> UInt32 {
    precondition(limit > 0)

    func nextRandom() -> UInt32 {
      var chunk: UInt32 = 0
      let status =
        SecRandomCopyBytes(kSecRandomDefault, MemoryLayout<UInt32>.size, &chunk)
      precondition(status == errSecSuccess)
      return chunk
    }

    var result: UInt32 = 0
    let upper = UInt32.max - (UInt32.max % limit)
    repeat {
      result = nextRandom()
    } while result >= upper
    return result % limit
  }
}

nonisolated private extension Array where Element == Character {
  mutating func shuffleSecure() {
    guard count > 1 else { return }
    for idx in stride(from: count - 1, through: 1, by: -1) {
      let swap = Int(UInt.randomSecure(limit: UInt32(idx + 1)))
      self.swapAt(idx, swap)
    }
  }
}
