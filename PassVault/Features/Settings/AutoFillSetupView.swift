//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct AutoFillSetupView: View {
  var body: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 18) {
        Text(
          String(
            localized:
              "Use these steps to let Safari and other apps suggest passwords you keep in PassVault."
          )
        )
        .font(.body)
        .foregroundStyle(Color.white.opacity(0.86))
        .fixedSize(horizontal: false, vertical: true)

        instructionStep(
          number: 1,
          text: String(localized: "Open the Settings app on this device."),
        )
        instructionStep(
          number: 2,
          text: String(localized: "Tap Passwords."),
        )
        instructionStep(
          number: 3,
          text: String(
            localized:
              "Tap Password Options (on some iOS versions this may appear as part of AutoFill & Passwords).",
          ),
        )
        instructionStep(
          number: 4,
          text: String(localized: "Turn on “AutoFill Passwords and Passkeys”."),
        )
        instructionStep(
          number: 5,
          text: String(
            localized:
              "Under “Use passwords and passkeys from”, turn on PassVault so it can fill your saved logins.",
          ),
        )

        Text(
          String(
            localized:
              "If PassVault does not appear, update to this build from Xcode and confirm the AutoFill extension target is embedded in the app you installed."
          )
        )
        .font(.footnote)
        .foregroundStyle(Color.white.opacity(0.55))
        .padding(.top, 4)
      }
      .padding(.horizontal, 18)
      .padding(.vertical, 20)
    }
    .vaultBackdrop()
    .navigationTitle(String(localized: "AutoFill setup"))
    .navigationBarTitleDisplayMode(.inline)
    .preferredColorScheme(.dark)
  }

  private func instructionStep(number: Int, text: String) -> some View {
    HStack(alignment: .top, spacing: 12) {
      Text("\(number)")
        .font(.caption.weight(.bold))
        .foregroundStyle(Color.white.opacity(0.95))
        .frame(width: 26, height: 26)
        .background(VaultGeneratorTheme.accent.opacity(0.38))
        .clipShape(Circle())
      Text(text)
        .font(.body)
        .foregroundStyle(Color.white.opacity(0.92))
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(14)
    .frame(maxWidth: .infinity, alignment: .leading)
    .vaultCard()
  }
}
