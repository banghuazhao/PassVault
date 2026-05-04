//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct BrandVisual: Equatable, Hashable {
  var accent: Color
  var symbolName: String
}

enum WebsiteBrandCatalog {

  private static let known: [(keys: [String], visual: BrandVisual)] = [
    (["google", "youtube", "gmail"], BrandVisual(accent: .red, symbolName: "g.circle.fill")),
    (["apple", "icloud", "me.com"], BrandVisual(accent: .secondary, symbolName: "apple.logo")),
    (["microsoft", "outlook", "live.com", "hotmail"], BrandVisual(accent: .cyan, symbolName: "square.grid.4x3.fill")),
    (["amazon", "aws"], BrandVisual(accent: .orange, symbolName: "cart.fill")),
    (["meta", "facebook", "instagram", "whatsapp"], BrandVisual(accent: .blue, symbolName: "bubble.left.and.bubble.right.fill")),
    (["github"], BrandVisual(accent: .purple, symbolName: "chevron.left.forwardslash.chevron.right")),
    (["twitter", "x.com"], BrandVisual(accent: .cyan, symbolName: "bird.fill")),
    (["linkedin"], BrandVisual(accent: .mint, symbolName: "person.2.circle.fill")),
    (["slack"], BrandVisual(accent: .indigo, symbolName: "number.square.fill")),
    (["stripe", "paypal"], BrandVisual(accent: .mint, symbolName: "dollarsign.circle.fill")),
    (["netflix"], BrandVisual(accent: .red, symbolName: "play.circle.fill")),
    (["spotify"], BrandVisual(accent: .green, symbolName: "music.note")),
    (["reddit"], BrandVisual(accent: .orange, symbolName: "bubble.left.and.text.bubble.right.fill")),
    (["ebay"], BrandVisual(accent: .blue, symbolName: "tag.fill")),
    (["dropbox"], BrandVisual(accent: .cyan, symbolName: "folder.fill")),
    (["notion"], BrandVisual(accent: .secondary, symbolName: "square.on.square")),
  ]

  /// Returns curated icon + tint when ``websiteHint`` resembles a recognizable service.
  static func brand(for websiteHint: String) -> BrandVisual? {
    let normalized = normalize(websiteHint)
    guard !normalized.isEmpty else { return nil }
    for bundle in Self.known {
      for key in bundle.keys where normalized.contains(key) {
        return bundle.visual
      }
    }
    return nil
  }

  private static func normalize(_ raw: String) -> String {
    var s = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    ["https://", "http://", "www.", "m."].forEach { token in s = s.replacingOccurrences(of: token, with: "") }

    guard let slash = s.firstIndex(of: "/") else { return s }
    return String(s[..<slash])
  }
}
