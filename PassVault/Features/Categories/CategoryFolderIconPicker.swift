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
        } label: {
          Image(systemName: name)
            .font(.title2)
            .foregroundStyle(Color.primary)
            .frame(maxWidth: .infinity)
            .padding(12)
            .background(
              RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(selectedSymbol == name ? Color.accentColor.opacity(0.28) : Color(uiColor: .tertiarySystemFill)),
            )
            .overlay(
              RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                  selectedSymbol == name ? Color.accentColor.opacity(0.9) : Color.clear,
                  lineWidth: 2,
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
