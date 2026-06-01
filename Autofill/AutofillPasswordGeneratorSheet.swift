//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct AutofillPasswordGeneratorSheet: View {
  fileprivate enum GenMode: String {
    case characters = "Characters"
    case words = "Words"
  }

  @Binding var password: String
  @Environment(\.dismiss) private var dismiss

  @State private var localPassword: String = ""
  @State private var mode: GenMode = .characters
  @State private var length = 30
  @State private var wordCount = 6
  @State private var useCapitals = true
  @State private var useDigits = true
  @State private var useSymbols = true
  @State private var titleCaseWords = false

  private var strength: PasswordStrengthLevel {
    PasswordStrengthEvaluator.evaluate(password: localPassword)
  }

  var body: some View {
    NavigationStack {
      ZStack {
        AutofillPalette.backdropTop.ignoresSafeArea()
        
        VStack(spacing: 0) {
          ScrollView {
            VStack(alignment: .leading, spacing: 0) {
              passwordBlock
              strengthRow
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

              Divider().opacity(0.15).padding(.horizontal, 16)

              VStack(alignment: .leading, spacing: 22) {
                Picker(String(localized: "Generator style"), selection: $mode) {
                  Text(String(localized: "Characters")).tag(GenMode.characters)
                  Text(String(localized: "Words")).tag(GenMode.words)
                }
                .pickerStyle(.segmented)
                .padding(.top, 16)

                if mode == .characters {
                  VStack(alignment: .leading, spacing: 10) {
                    HStack {
                      Text(String(localized: "Length: \(length)"))
                        .font(.body.weight(.medium))
                        .foregroundStyle(.white.opacity(0.9))
                      Spacer()
                    }
                    Slider(value: Binding(get: { Double(length) }, set: { length = Int($0) }), in: 8 ... 64, step: 1)
                      .tint(AutofillGeneratorTheme.accent)
                  }

                  VStack(spacing: 14) {
                    Toggle(String(localized: "Use capitals (A–Z)"), isOn: $useCapitals)
                    Toggle(String(localized: "Use digits (0–9)"), isOn: $useDigits)
                    Toggle(String(localized: "Use symbols (@ ! & *)"), isOn: $useSymbols)
                  }
                  .tint(AutofillGeneratorTheme.accent)
                  .foregroundStyle(.white.opacity(0.9))
                } else {
                  VStack(alignment: .leading, spacing: 10) {
                    HStack {
                      Text(String(localized: "Words: \(wordCount)"))
                        .font(.body.weight(.medium))
                        .foregroundStyle(.white.opacity(0.9))
                      Spacer()
                    }
                    Slider(value: Binding(get: { Double(wordCount) }, set: { wordCount = Int($0) }), in: 3 ... 12, step: 1)
                      .tint(AutofillGeneratorTheme.accent)
                  }

                  Toggle(String(localized: "Capitalize each word"), isOn: $titleCaseWords)
                    .tint(AutofillGeneratorTheme.accent)
                    .foregroundStyle(.white.opacity(0.9))
                }
              }
              .padding(.horizontal, 20)
              .padding(.vertical, 12)

              bottomActionBar
                .padding(.vertical, 32)
            }
          }
        }
      }
      .navigationTitle(String(localized: "Generator"))
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(String(localized: "Close")) { dismiss() }
            .foregroundStyle(.white)
        }
      }
      .toolbarBackground(AutofillPalette.backdropTop, for: .navigationBar)
      .toolbarColorScheme(.dark, for: .navigationBar)
    }
    .onAppear {
      localPassword = password
      if localPassword.isEmpty {
        rollPassword()
      }
    }
    .onChange(of: mode) { _, _ in regenerateFromSettings() }
    .onChange(of: length) { _, _ in regenerateFromSettings() }
    .onChange(of: useCapitals) { _, _ in regenerateFromSettings() }
    .onChange(of: useDigits) { _, _ in regenerateFromSettings() }
    .onChange(of: useSymbols) { _, _ in regenerateFromSettings() }
    .onChange(of: wordCount) { _, _ in regenerateFromSettings() }
    .onChange(of: titleCaseWords) { _, _ in regenerateFromSettings() }
    .preferredColorScheme(.dark)
  }

  private var passwordBlock: some View {
    Text(localPassword.isEmpty ? " " : localPassword)
      .font(.system(.title3, design: .monospaced).weight(.medium))
      .multilineTextAlignment(.leading)
      .frame(maxWidth: .infinity, alignment: .leading)
      .frame(minHeight: 100)
      .padding(.horizontal, 20)
      .padding(.vertical, 18)
      .background(Color.white.opacity(0.05))
      .foregroundStyle(.white)
  }

  private var strengthRow: some View {
    HStack(spacing: 8) {
      Image(systemName: strength == .weak ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
        .foregroundStyle(strength.tint)
      Text(strength.passwordBannerTitle)
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(strength.tint)
      Spacer()
    }
    .padding(.horizontal, 20)
    .padding(.top, 12)
  }

  private var bottomActionBar: some View {
    HStack(spacing: 16) {
      Button {
        rollPassword()
      } label: {
        Label(String(localized: "Generate"), systemImage: "arrow.clockwise")
          .font(.headline)
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.white.opacity(0.1))
          .foregroundStyle(.white)
          .clipShape(RoundedRectangle(cornerRadius: 14))
      }
      .buttonStyle(.plain)

      Button {
        password = localPassword
        dismiss()
      } label: {
        Text(String(localized: "Use Password"))
          .font(.headline)
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity)
          .padding()
          .background(AutofillGeneratorTheme.accent)
          .clipShape(RoundedRectangle(cornerRadius: 14))
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, 20)
  }

  private func rollPassword() {
    regenerateFromSettings()
  }

  private func regenerateFromSettings() {
    do {
      switch mode {
      case .characters:
        if !useCapitals && !useDigits && !useSymbols {
          useDigits = true
        }
        localPassword = try SecurePasswordGenerator.generate(
          length: length,
          includeUpper: useCapitals,
          includeLower: true,
          includeDigits: useDigits,
          includeSymbols: useSymbols
        )
      case .words:
        var next = try SecurePasswordGenerator.generatePassphrase(wordCount: wordCount)
        if titleCaseWords {
          next = next.split(separator: " ").map { $0.capitalized }.joined(separator: " ")
        }
        localPassword = next
      }
    } catch {
      // ignore
    }
  }
}
