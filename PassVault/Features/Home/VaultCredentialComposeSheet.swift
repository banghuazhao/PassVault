//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI
import UIKit

struct VaultCredentialComposeSheet: View {
    enum Mode {
        case create(initialCategoryHint: Int?)
        case modify(VaultPasswordRow)
    }

    let homeModel: HomeViewModel
    let mode: Mode
    let onFinished: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var hydrated = false
    @State private var bucket = 0
    @State private var label = ""
    @State private var secret = ""
    @State private var site = ""
    @State private var memo = ""
    @State private var adornment = ""
    @State private var cadence = 0
    @State private var generator = false
    @State private var symbolPicker = false
    @State private var passwordVisible = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    listIconHero
                        .frame(maxWidth: .infinity)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowBackground(Color.clear)
                }

                Section(String(localized: "Category")) {
                    Picker(String(localized: "Folder"), selection: $bucket) {
                        ForEach(homeModel.categories) { cat in
                            Text(cat.name).tag(cat.id)
                        }
                    }
                }

                Section(String(localized: "Details")) {
                    TextField(String(localized: "Title"), text: $label)
                    passwordEntryRow
                    Button {
                        generator = true
                    } label: {
                        Label(String(localized: "Password generator"), systemImage: "wand.and.stars")
                    }

                    TextField(String(localized: "Website (optional)"), text: $site)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                }

                Section(String(localized: "Notes")) {
                    TextField(String(localized: "Notes"), text: $memo, axis: .vertical)
                }

                Section {
                    Picker(String(localized: "Remind to update password"), selection: $cadence) {
                        Text(String(localized: "Never")).tag(0)
                        Text(String(localized: "Every month")).tag(1)
                        Text(String(localized: "Every 3 months")).tag(3)
                        Text(String(localized: "Every 6 months")).tag(6)
                        Text(String(localized: "Every 12 months")).tag(12)
                    }
                } header: {
                    Text(String(localized: "Password update reminder"))
                } footer: {
                    Text(
                        String(
                            localized:
                            "Sends a local notification when this password should be rotated. Does not upload anything.",
                        )
                    )
                    .font(.caption)
                }
            }
            .navigationTitle(modeTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Close")) {
                        dismiss()
                        onFinished()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Save")) {
                        Task { await save() }
                    }
                    .disabled(!canPersist)
                }
            }
            .sheet(isPresented: $generator) {
                PasswordGeneratorSheet(password: $secret)
            }
            .sheet(isPresented: $symbolPicker) {
                VaultEmojiPickerSheet(selection: $adornment)
            }
        }
        .onAppear(perform: prime)
    }

    @ViewBuilder
    private var listIconHero: some View {
        let trimmed = adornment.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasCustom = !trimmed.isEmpty

        VStack(spacing: 14) {
            Button {
                symbolPicker = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color(uiColor: .tertiarySystemFill))
                    Circle()
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
                    iconHeroGlyph
                }
                .frame(width: 80, height: 80)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "List icon"))
            .accessibilityHint(String(localized: "Choose an emoji shown next to this item in the list."))

            VStack(spacing: 6) {
                if hasCustom {
                    Button(String(localized: "Remove"), role: .destructive) {
                        adornment = ""
                    }
                    .font(.footnote.weight(.medium))
                }
            }
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private var iconHeroGlyph: some View {
        let trimmed = adornment.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty, UIImage(systemName: trimmed) != nil {
            Image(systemName: trimmed)
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
                .symbolRenderingMode(.hierarchical)
        } else if !trimmed.isEmpty {
            Text(trimmed)
                .font(.system(size: 36))
                .minimumScaleFactor(0.35)
                .lineLimit(1)
        } else if let digits = Self.titlePreview(from: label) {
            Text(digits)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
        } else {
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .medium))
                .foregroundStyle(.tertiary)
        }
    }

    private static func titlePreview(from title: String) -> String? {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return nil }
        return String(t.prefix(2))
    }

    /// Password field + show/hide (eye) control.
    private var passwordEntryRow: some View {
        HStack(spacing: 10) {
            Group {
                if passwordVisible {
                    TextField(String(localized: "Password"), text: $secret)
                        .textContentType(.password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } else {
                    SecureField(String(localized: "Password"), text: $secret)
                        .textContentType(.password)
                }
            }

            Button {
                passwordVisible.toggle()
            } label: {
                Image(systemName: passwordVisible ? "eye.slash.fill" : "eye.fill")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(
                passwordVisible
                    ? String(localized: "Hide password")
                    : String(localized: "Show password"),
            )
        }
    }

    private var modeTitle: String {
        switch mode {
        case .create: String(localized: "New credential")
        case .modify: String(localized: "Edit credential")
        }
    }

    private var canPersist: Bool {
        guard !secret.isEmpty else { return false }
        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        return homeModel.categories.contains(where: { $0.id == bucket })
    }

    private func prime() {
        guard !hydrated else { return }
        hydrated = true
        guard let firstId = homeModel.categories.first?.id else { return }
        switch mode {
        case let .create(hint):

            bucket = hint ?? firstId
        case let .modify(row):
            bucket = row.categoryId
            label = row.title
            site = row.website
            memo = row.notes
            adornment = row.customIconSFName ?? ""
            cadence = row.reminderIntervalMonths ?? 0
            secret = homeModel.plaintext(for: row)
        }
        if bucket == 0 {
            bucket = firstId
        }
    }

    @MainActor
    private func save() async {
        let icon = adornment.trimmingCharacters(in: .whitespacesAndNewlines)
        let months = cadence == 0 ? nil : cadence
        let iconValue = icon.isEmpty ? nil : icon
        let kindRaw = PassVaultEntryKind.login.rawValue
        switch mode {
        case .create:
            _ = await homeModel.insertPassword(
                categoryId: bucket,
                title: label.trimmingCharacters(in: .whitespacesAndNewlines),
                password: secret,
                entryKindRaw: kindRaw,
                website: site.trimmingCharacters(in: .whitespacesAndNewlines),
                notes: memo.trimmingCharacters(in: .whitespacesAndNewlines),
                customIconSFName: iconValue,
                reminderMonths: months,
            )
        case let .modify(row):
            _ = await homeModel.updatePassword(
                row,
                categoryId: bucket,
                title: label.trimmingCharacters(in: .whitespacesAndNewlines),
                password: secret,
                entryKindRaw: kindRaw,
                website: site.trimmingCharacters(in: .whitespacesAndNewlines),
                notes: memo.trimmingCharacters(in: .whitespacesAndNewlines),
                customIconSFName: iconValue,
                reminderMonths: months,
            )
        }
        dismiss()
        onFinished()
    }
}
