//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI
import UIKit

private enum PasswordGeneratorHistory {
  private static let key = "passvault.generator.history"
  private static let maxItems = 40

  static func load() -> [String] {
    guard let data = UserDefaults.standard.data(forKey: key),
      let list = try? JSONDecoder().decode([String].self, from: data)
    else { return [] }
    return list
  }

  static func append(_ value: String) {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    var list = load()
    list.removeAll { $0 == trimmed }
    list.insert(trimmed, at: 0)
    if list.count > maxItems { list = Array(list.prefix(maxItems)) }
    if let data = try? JSONEncoder().encode(list) {
      UserDefaults.standard.set(data, forKey: key)
    }
  }
}

struct PasswordGeneratorSheet: View {
  fileprivate enum GenMode: String {
    case characters = "Characters"
    case words = "Words"
  }

  @Binding var password: String
  @Environment(\.dismiss) private var dismiss
  @Environment(\.copyToastHost) private var copyToastHost

  @State private var mode: GenMode = .characters
  @State private var length = 30
  @State private var wordCount = 6
  @State private var useCapitals = true
  @State private var useDigits = true
  @State private var useSymbols = true
  @State private var titleCaseWords = false
  @State private var historyItems: [String] = PasswordGeneratorHistory.load()
  @State private var showHistory = false

  private var strength: PasswordStrengthLevel {
    PasswordStrengthEvaluator.evaluate(password: password)
  }

  var body: some View {
    VStack(spacing: 0) {
      headerBar

      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          passwordBlock
          strengthRow
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

          Divider().opacity(0.25).padding(.horizontal, 16)

          VStack(alignment: .leading, spacing: 18) {
            Picker(String(localized: "Generator style"), selection: $mode) {
              Text(String(localized: "Characters")).tag(GenMode.characters)
              Text(String(localized: "Words")).tag(GenMode.words)
            }
            .pickerStyle(.segmented)
            .padding(.top, 16)

            if mode == .characters {
              HStack {
                Text(String(localized: "Length: \(length)"))
                  .font(.body.weight(.medium))
                  .foregroundStyle(.primary)
                Spacer()
              }
              Slider(value: Binding(get: { Double(length) }, set: { length = Int($0) }), in: 8 ... 64, step: 1)
                .tint(VaultGeneratorTheme.accent)

              Toggle(String(localized: "Use capital letters (A–Z)"), isOn: $useCapitals)
                .tint(VaultGeneratorTheme.accent)
              Toggle(String(localized: "Use digits (0–9)"), isOn: $useDigits)
                .tint(VaultGeneratorTheme.accent)
              Toggle(String(localized: "Use symbols (@ ! & *)"), isOn: $useSymbols)
                .tint(VaultGeneratorTheme.accent)
            } else {
              HStack {
                Text(String(localized: "Words: \(wordCount)"))
                  .font(.body.weight(.medium))
                Spacer()
              }
              Slider(value: Binding(get: { Double(wordCount) }, set: { wordCount = Int($0) }), in: 3 ... 12, step: 1)
                .tint(VaultGeneratorTheme.accent)

              Toggle(String(localized: "Capitalize each word"), isOn: $titleCaseWords)
                .tint(VaultGeneratorTheme.accent)
            }
          }
          .padding(.horizontal, 20)
          .padding(.vertical, 12)

          bottomActionBar
            .padding(.vertical, 20)
        }
//        .padding(.horizontal, 12)
//        .padding(.top, 8)
        .background(
          RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Color(.systemBackground))
            .shadow(color: .black.opacity(0.08), radius: 12, y: 4),
        )
       
      }
      .frame(maxWidth: .infinity)
      .background(Color(.systemGroupedBackground))
    }
    .background(Color.black.ignoresSafeArea(edges: .top))
    .onAppear {
      historyItems = PasswordGeneratorHistory.load()
      if password.isEmpty {
        rollPassword()
      }
    }
    .onChange(of: mode) { _, _ in
      regenerateFromSettings(recordHistory: false)
    }
    .onChange(of: length) { _, _ in
      guard mode == .characters else { return }
      regenerateFromSettings(recordHistory: false)
    }
    .onChange(of: useCapitals) { _, _ in
      guard mode == .characters else { return }
      regenerateFromSettings(recordHistory: false)
    }
    .onChange(of: useDigits) { _, _ in
      guard mode == .characters else { return }
      regenerateFromSettings(recordHistory: false)
    }
    .onChange(of: useSymbols) { _, _ in
      guard mode == .characters else { return }
      regenerateFromSettings(recordHistory: false)
    }
    .onChange(of: wordCount) { _, _ in
      guard mode == .words else { return }
      regenerateFromSettings(recordHistory: false)
    }
    .onChange(of: titleCaseWords) { _, _ in
      guard mode == .words else { return }
      regenerateFromSettings(recordHistory: false)
    }
    .sheet(isPresented: $showHistory) {
      NavigationStack {
        List {
          ForEach(historyItems, id: \.self) { item in
            Button {
              password = item
              showHistory = false
            } label: {
              Text(item)
                .font(.body.monospaced())
                .lineLimit(3)
            }
          }
        }
        .navigationTitle(String(localized: "Generated history"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .confirmationAction) {
            Button(String(localized: "Done")) { showHistory = false }
          }
        }
      }
    }
  }

  private var headerBar: some View {
    HStack {
      Button {
        dismiss()
      } label: {
        Image(systemName: "xmark")
          .font(.body.weight(.semibold))
          .foregroundStyle(.white)
          .frame(width: 44, height: 44)
      }
      Spacer()
      Text(String(localized: "Password Generator"))
        .font(.headline.weight(.semibold))
        .foregroundStyle(.white)
      Spacer()
      Button {
        historyItems = PasswordGeneratorHistory.load()
        showHistory = true
      } label: {
        Image(systemName: "clock.arrow.circlepath")
          .font(.body.weight(.semibold))
          .foregroundStyle(.white)
          .frame(width: 44, height: 44)
      }
    }
    .padding(.horizontal, 4)
    .padding(.bottom, 12)
    .background(Color.black)
  }

  private var passwordBlock: some View {
    Text(passwordDigitAttributed)
      .multilineTextAlignment(.leading)
      .frame(maxWidth: .infinity, alignment: .leading)
      .frame(minHeight: 80)
      .padding(.horizontal, 20)
      .padding(.vertical, 18)
      .background(Color(.secondarySystemBackground))
  }

  private var passwordDigitAttributed: AttributedString {
    let s = password.isEmpty ? " " : password
    let mas = NSMutableAttributedString(string: s)
    let len = (s as NSString).length
    let baseSize: CGFloat = UIFont.preferredFont(forTextStyle: .title3).pointSize
    let font = UIFont.monospacedSystemFont(ofSize: baseSize, weight: .regular)
    mas.addAttribute(.font, value: font, range: NSRange(location: 0, length: len))
    mas.addAttribute(.foregroundColor, value: UIColor.label, range: NSRange(location: 0, length: len))

    let digitColor = UIColor(VaultGeneratorTheme.digitHighlight)
    (s as NSString).enumerateSubstrings(
      in: NSRange(location: 0, length: len),
      options: .byComposedCharacterSequences,
    ) { substring, range, _, _ in
      guard let substring, substring.count == 1, substring.first?.isNumber == true else { return }
      mas.addAttribute(.foregroundColor, value: digitColor, range: range)
    }

    return AttributedString(mas)
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
  }

  private var bottomActionBar: some View {
    HStack(spacing: 0) {
      generatorAction(
        title: String(localized: "Copy"),
        systemImage: "doc.on.doc",
        action: { ClipboardFacade.copy(password, toastHost: copyToastHost) },
      )
      generatorAction(
        title: String(localized: "Generate"),
        systemImage: "arrow.clockwise",
        action: { rollPassword() },
      )
      generatorAction(
        title: String(localized: "Save"),
        systemImage: "plus.square.fill",
        action: {
          PasswordGeneratorHistory.append(password)
          dismiss()
        },
      )
    }
    .padding(.horizontal, 12)
  }

  private func generatorAction(title: String, systemImage: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      VStack(spacing: 10) {
        ZStack {
          Circle()
            .fill(Color(.secondarySystemFill))
            .frame(width: 56, height: 56)
          Image(systemName: systemImage)
            .font(.title3.weight(.semibold))
            .foregroundStyle(.primary)
        }
        Text(title)
          .font(.caption.weight(.medium))
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity)
    }
    .buttonStyle(.plain)
  }

  private func rollPassword() {
    regenerateFromSettings(recordHistory: true)
  }

  /// Regenerates the bound password from current controls. Optionally appends to in-sheet history (manual Generate only).
  private func regenerateFromSettings(recordHistory: Bool) {
    do {
      switch mode {
      case .characters:
        if !useCapitals && !useDigits && !useSymbols {
          useDigits = true
        }
        let next = try SecurePasswordGenerator.generate(
          length: length,
          includeUpper: useCapitals,
          includeLower: true,
          includeDigits: useDigits,
          includeSymbols: useSymbols,
        )
        password = next
      case .words:
        var next = try SecurePasswordGenerator.generatePassphrase(wordCount: wordCount)
        if titleCaseWords {
          next =
            next
            .split(separator: " ")
            .map { $0.capitalized }
            .joined(separator: " ")
        }
        password = next
      }
      if recordHistory {
        PasswordGeneratorHistory.append(password)
        historyItems = PasswordGeneratorHistory.load()
      }
    } catch {
      // Keep prior password if generation fails
    }
  }
}

// MARK: - Theme (matches reference: teal controls + purple digits)

enum VaultGeneratorTheme {
  static let accent = Color(red: 0.12, green: 0.72, blue: 0.58)
  static let digitHighlight = Color(red: 0.48, green: 0.36, blue: 0.88)
}
