//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

/// Common SF Symbols for folder categories; tap to select (no manual symbol typing).
struct CategoryFolderIconPicker: View {
  @Binding var selectedSymbol: String

  private let columns = [GridItem(.adaptive(minimum: 52), spacing: 10)]

  /// Curated set that renders well at small sizes.
  private static let symbols: [String] = [
    "folder.fill",
    "tray.2.fill",
    "archivebox.fill",
    "shippingbox.fill",
    "briefcase.fill",
    "building.2.fill",
    "house.fill",
    "globe",
    "wifi",
    "key.fill",
    "lock.fill",
    "lock.open.fill",
    "creditcard.fill",
    "banknote.fill",
    "cart.fill",
    "star.fill",
    "heart.fill",
    "flag.fill",
    "flame.fill",
    "leaf.fill",
    "cross.case.fill",
    "pills.fill",
    "airplane",
    "car.fill",
    "gamecontroller.fill",
    "book.fill",
    "graduationcap.fill",
    "doc.text.fill",
    "person.crop.circle.fill",
    "cloud.fill",
  ]

  var body: some View {
    LazyVGrid(columns: columns, spacing: 12) {
      ForEach(Self.symbols, id: \.self) { name in
        Button {
          selectedSymbol = name
          Haptics.selection()
        } label: {
          Image(systemName: name)
            .symbolRenderingMode(.hierarchical)
            .font(.title2.weight(.medium))
            .foregroundStyle(selectedSymbol == name ? Color.accentColor : Color.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
              RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(selectedSymbol == name ? Color.accentColor.opacity(0.12) : Color.white.opacity(0.05)),
            )
            .overlay(
              RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                  selectedSymbol == name ? Color.accentColor.opacity(0.4) : Color.white.opacity(0.05),
                  lineWidth: 1,
                ),
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(name.replacingOccurrences(of: ".", with: " ")))
      }
    }
    .padding(.vertical, 4)
  }
}
