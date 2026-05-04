//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI
import UIKit

/// Visual identity: custom emoji (or legacy SF Symbol), numeric title chip, curated brands, then initials.
struct VaultEntryAvatarView: View {
  let row: VaultPasswordRow

  var body: some View {
    let brand = WebsiteBrandCatalog.brand(for: row.website)

    Group {
      if let custom = trimmedCustomIcon,
        !custom.isEmpty {
        if UIImage(systemName: custom) != nil {
          avatarCircle(background: Color.white.opacity(0.07)) {
            Image(systemName: custom)
              .foregroundStyle(Color.white)
          }
        }
        else {
          avatarCircle(background: Color.white.opacity(0.1)) {
            Text(custom)
              .font(.system(size: 26))
              .minimumScaleFactor(0.5)
              .lineLimit(1)
          }
        }
      }
      else if let digits = row.numericTitleIconText {
        avatarCircle(background: Color.white.opacity(0.12)) {
          Text(digits)
            .font(.title2.weight(.bold))
            .foregroundStyle(Color.white.opacity(0.92))
            .minimumScaleFactor(0.5)
            .lineLimit(1)
        }
      }
      else if let brand {
        avatarCircle(background: brand.accent.opacity(0.3)) {
          Image(systemName: brand.symbolName)
            .foregroundStyle(brand.accent)
        }
      }
      else {
        avatarCircle(background: Color.secondary.opacity(0.25)) {
          Text(initial(from: row))
            .font(.title.bold())
            .foregroundStyle(Color.white.opacity(0.85))
            .minimumScaleFactor(0.65)
            .padding(10)
        }
      }
    }
    .frame(width: 48, height: 48)
    .accessibilityHidden(true)
  }

  private var trimmedCustomIcon: String? {
    row.customIconSFName?.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func avatarCircle<Content: View>(
    background: Color,
    @ViewBuilder content: () -> Content,
  )
    -> some View
  {
    ZStack {
      Circle().fill(background)
      content()
    }
  }

  private func initial(from row: VaultPasswordRow) -> String {
    let source =
      row.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      ? row.website.trimmingCharacters(in: .whitespacesAndNewlines)
      : row.title
    guard let letter = source.first(where: { $0.isLetter }) else { return "?" }
    return String(letter).uppercased()
  }
}
