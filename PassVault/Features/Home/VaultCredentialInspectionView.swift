//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct VaultCredentialInspectionView: View {
    let entry: VaultPasswordRow
    let homeModel: HomeViewModel
    let onCompose: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.copyToastHost) private var copyToastHost

    @State private var unveil = false
    @State private var purgeWarn = false

    private var reveal: String {
        homeModel.plaintext(for: entry)
    }

    private var guardrail: PasswordStrengthLevel {
        PasswordStrengthEvaluator.evaluate(password: reveal)
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        VaultEntryAvatarView(row: entry)
                        HStack {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(guardrail.displayTitle)
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(guardrail.tint)

                                Text(unveil ? reveal : dots(reveal))
                                    .font(.system(.body, design: .monospaced))
                            }
                            
                            Spacer()

                            VStack(spacing: 8) {
                                Button {
                                    unveil.toggle()
                                } label: {
                                    Image(systemName: unveil ? "eye.slash.fill" : "eye.fill")
                                        .font(.body)
                                        .frame(minWidth: 24, minHeight: 24)
                                }
                                .buttonStyle(.bordered)
                                .accessibilityLabel(
                                    unveil
                                        ? String(localized: "Hide password")
                                        : String(localized: "Reveal password"),
                                )

                                Button {
                                    ClipboardFacade.copy(reveal, toastHost: copyToastHost)
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                        .font(.body)
                                        .frame(minWidth: 24, minHeight: 24)
                                }
                                .buttonStyle(.bordered)
                                .disabled(reveal.isEmpty)
                                .accessibilityLabel(String(localized: "Copy secret"))
                            }
                        }
                    }
                }
            } header: {
                Text(String(localized: "Passphrase"))
            }

            Section(String(localized: "Metadata")) {
                copyableLabeled(String(localized: "Title"), value: entry.title)
                copyableLabeled(String(localized: "Website"), value: entry.website)

                LabeledContent(String(localized: "Category")) {
                    HStack(spacing: 8) {
                        Text(homeModel.categoryName(for: entry.categoryId) ?? "—")
                        if let name = homeModel.categoryName(for: entry.categoryId),
                           !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            categoryCopyButton(text: name)
                        }
                    }
                }
            }

            if !entry.notes.isEmpty {
                Section {
                    Text(entry.notes)
                } header: {
                    Text(String(localized: "Notes"))
                }
            }

            if let cadence = entry.reminderIntervalMonths, cadence > 0 {
                Section(String(localized: "Password update")) {
                    LabeledContent(String(localized: "Update interval")) {
                        Text(String(localized: "Every \(cadence) months"))
                    }
                    if let due = entry.reminderNextDue {
                        LabeledContent(String(localized: "Next reminder")) {
                            Text(due, format: .dateTime.day().month().year())
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .vaultBackdrop()
        .navigationTitle(entry.title.isEmpty ? String(localized: "Vault item") : entry.title)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(String(localized: "Edit")) { onCompose() }
                Button(role: .destructive) { purgeWarn = true } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .confirmationDialog(
            String(localized: "Permanently erase this vault record?"),
            isPresented: $purgeWarn,
            titleVisibility: .visible,
        ) {
            Button(String(localized: "Erase"), role: .destructive) {
                Task {
                    await homeModel.deletePassword(entry)
                    dismiss()
                }
            }
            Button(String(localized: "Cancel"), role: .cancel, action: {})
        }
        .onAppear {
            Task {
                await homeModel.recordAccess(entry)
            }
        }
    }

    @ViewBuilder
    private func copyableLabeled(_ title: String, value: String) -> some View {
        LabeledContent(title) {
            HStack(spacing: 8) {
                Text(value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "—" : value)
                    .multilineTextAlignment(.trailing)
                if !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button {
                        ClipboardFacade.copy(value, toastHost: copyToastHost)
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel(String(localized: "Copy"))
                }
            }
        }
    }

    private func categoryCopyButton(text: String) -> some View {
        Button {
            ClipboardFacade.copy(text, toastHost: copyToastHost)
        } label: {
            Image(systemName: "doc.on.doc")
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(String(localized: "Copy"))
    }

    private func dots(_ passphrase: String) -> String {
        String(repeating: "\u{2022}", count: min(max(passphrase.count, 6), 18))
    }
}
