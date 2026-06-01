//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI
import Security

// MARK: - PasswordStrengthLevel

enum PasswordStrengthLevel: String {
  case weak
  case medium
  case strong

  var displayTitle: String {
    switch self {
    case .weak: String(localized: "Weak")
    case .medium: String(localized: "Medium")
    case .strong: String(localized: "Strong")
    }
  }

  var passwordBannerTitle: String {
    switch self {
    case .weak: String(localized: "Weak password")
    case .medium: String(localized: "Medium password")
    case .strong: String(localized: "Strong password")
    }
  }

  var tint: Color {
    switch self {
    case .weak: .orange
    case .medium: .yellow
    case .strong: .green
    }
  }
}

enum PasswordStrengthEvaluator {
  nonisolated static func evaluate(password: String) -> PasswordStrengthLevel {
    guard !password.isEmpty else { return .weak }

    let length = password.count
    let hasUpper = password.contains { $0.isUppercase }
    let hasLower = password.contains { $0.isLowercase }
    let hasDigit = password.contains(where: \.isNumber)
    let hasSymbol = password.contains(where: {
      "!@#$%^&*()_-+=[]{}/?.,;:<>|\\~`'\"¡§•£¥€¶ç".contains($0)
    })

    var classes = 0
    if hasUpper { classes += 1 }
    if hasLower { classes += 1 }
    if hasDigit { classes += 1 }
    if hasSymbol { classes += 1 }

    if length >= 16, classes >= 3 { return .strong }
    if length >= 12, classes >= 3 { return .strong }
    if length >= 10, classes >= 2 { return .medium }
    if length >= 8, classes >= 2 { return .medium }
    if length <= 7 { return .weak }
    return .medium
  }
}

// MARK: - SecurePasswordGenerator

enum SecurePasswordGenerator {
  enum GeneratorError: Error {
    case emptyCharset
  }

  private static let upper = Array("ABCDEFGHJKLMNPQRSTUVWXYZ")
  private static let lower = Array("abcdefghijkmnopqrstuvwxyz")
  private static let digits = Array("23456789")
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
    if includeUpper { ensured.append(upper.randomSecureElement()) }
    if includeLower { ensured.append(lower.randomSecureElement()) }
    if includeDigits { ensured.append(digits.randomSecureElement()) }
    if includeSymbols { ensured.append(symbols.randomSecureElement()) }

    guard ensured.count <= length else { throw GeneratorError.emptyCharset }

    var output = ensured
    let remaining = length - output.count

    for _ in 0 ..< remaining {
      output.append(pool.randomSecureElement())
    }

    output.shuffleSecure()
    return String(output)
  }

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

  mutating func shuffleSecure() {
    guard count > 1 else { return }
    for idx in stride(from: count - 1, through: 1, by: -1) {
      let swap = Int(UInt.randomSecure(limit: UInt32(idx + 1)))
      self.swapAt(idx, swap)
    }
  }
}

nonisolated private extension UInt {
  static func randomSecure(limit: UInt32) -> UInt32 {
    precondition(limit > 0)
    func nextRandom() -> UInt32 {
      var chunk: UInt32 = 0
      let status = SecRandomCopyBytes(kSecRandomDefault, MemoryLayout<UInt32>.size, &chunk)
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

// MARK: - PassphraseWordPool

nonisolated enum PassphraseWordPool {
  nonisolated static let words: [String] = {
    let raw = """
      ablaze acorn agenda alpine anchor apple april atlas autum azure bacon badge ballad bamboo \
      beacon berry birch blaze blimp bloom bolt brass breeze brick bright brisk bronze brook \
      brush buffalo bundle butter camel canyon carol cedar chance cherry chilly cider cobalt \
      comet cosmic cradle cricket crystal current dagger dapper delta desert diesel dolphin \
      domain dragon drizzle eagle edison elder emerald engine fabric falcon fennel fever \
      flamingo flint forest formal fossil fountain galaxy garden garlic ginger glacier glitter \
      gondola griffin harvest helmet horizon humming iceberg igloo indoor invent ivory jasper \
      jigsaw jumbo juniper kennel kernel kindle lantern legend lotus lunar lyric maple marble \
      meteor midnight mimic monarch mosaic motion neon noble nordic oasis object ocean olive \
      orbit orchid paper paprika parchment pebble pegasus penguin phantom picnic pilot pioneer \
      pixel plaza polar prairie prism puzzle quartz quiver raptor raven relay ribbon rocket \
      rustic sailor satsuma saffron satellite savanna schema scooter season shadow shark shelter \
      shimmer signal silent silver skyline soda sonar sonic spark sphere spiral spruce squirrel \
      stencil summit sunset surfer swallow swift symbol tablet talon temple timber tonic torch \
      tower trail travel treble tropical tundra turbine twilight umbrella unicorn valley vector \
      velvet vendor vertex vintage violet vivid volcano voyage waffle wander warp winter wisdom \
      woodland wren zenith zipper zodiac absolve adjust admit advance agenda airborne album \
      almond ambient ancient anchor anthem apart arcade archive armor arrow aspect aurora axiom \
      badge balloon banquet barrier basket battery beacon bedrock beehive berries blossom \
      blueprint bracket brave breeze bridge bright brochure budget bumper bundle burrow camel \
      canyon cascade castle cattle census chamber channel chapter cheetah cherry cherry civic \
      cluster cobra compass concert coral cosmic cricket crystal cycle dagger dancer derby desert \
      diamond diesel dolphin domain draft dragon drift durable dynamic echo eddy elegant element \
      ember engine enjoy enrich episode equinox escape essence evening fabric falcon fantasy \
      fathom feather festival fiction fieldstone filament final finish flavor flex flight flour \
      foliage forever forum fossil fountain freeze frontier galaxy garment gentle glacier golden \
      graceful granite gravity guitar habitat harbor harvest helmet hero hidden hillside horizon \
      hybrid iceberg imagine impact indoor inferno inkjet island ivory jasmine journey jubilee \
      jungle justice kernel kinetic lagoon lantern latitude lattice legend liberty lightning \
      limestone lion lunar lyric magnetic mandarin maple marble maritime marker meadow melody \
      meteor midnight mimic mosaic motion mountain native nectar neon nightingale noble northern \
      notion oasis objective observe ocean official orange orchard orbit orchid outdoor ozone \
      pacific palette paper parade parsley pastel patrol pave pearl penguin picnic pilot pioneer \
      pixel plaza polar prairie prelude prism puzzle quartz quiet racing raptor raven recycle \
      relay ribbon ripple ritual rocket rustic safari sailor satellite scaffold season shadow \
      sherbet shimmer signal silent silver skyline soda sonar sonic sparkle spiral spruce squirrel \
      stadium stencil sterling stormy summit sunset surfer swallow swift symbol tablet talon \
      temple thunder timber tonic torch tornado tower trail transit travel treble tremor \
      tropical tumble tunnel tundra turbine twilight umbrella unicorn valley vector velvet vendor \
      vertex vintage violet vivid volcano voyage waffle wander warmth warp winter wisdom wooden \
      woodland woven wreath wren zenith zephyr zipper zodiac zoom
      """
    return raw.split(whereSeparator: { $0.isWhitespace }).map(String.init)
  }()
}
