//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

enum VaultPalette {
  static let backdropTop = Color(red: 12 / 255, green: 15 / 255, blue: 28 / 255)
  static let backdropBottom = Color(red: 23 / 255, green: 30 / 255, blue: 45 / 255)
  static let elevatedCard = Color.white.opacity(0.06)
  static let mutedText = Color.white.opacity(0.65)
}

struct VaultGlassCard: ViewModifier {
  func body(content: Content) -> some View {
    content
      .padding(16)
      .background(
        RoundedRectangle(cornerRadius: 20, style: .continuous)
          .fill(.ultraThinMaterial)
          .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
              .stroke(Color.white.opacity(0.06), lineWidth: 1),
          ),
      )
  }
}

extension View {
  func vaultCard() -> some View {
    modifier(VaultGlassCard())
  }

  func vaultBackdrop() -> some View {
    background(
      LinearGradient(
        colors: [VaultPalette.backdropTop, VaultPalette.backdropBottom],
        startPoint: .topLeading,
        endPoint: .bottomTrailing,
      )
      .ignoresSafeArea(),
    )
  }
}
