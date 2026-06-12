//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct HomePaneView: View {
  @Bindable private var model: HomeViewModel
  @State private var composing: VaultComposerSurface?
  @Environment(\.copyToastHost) private var copyToastHost

  init(model: HomeViewModel) {
    self.model = model
  }

  var body: some View {
    NavigationStack {
      credentialList
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("")
        .searchable(text: $model.searchQuery, placement: .navigationBarDrawer(displayMode: .always))
        .toolbar {
          ToolbarItem(placement: .principal) {
            categoryFilterMenu
          }
          ToolbarItem(placement: .topBarLeading) {
            sortMenu
          }
          ToolbarItem(placement: .topBarTrailing) {
            Button {
              composing = .compose(categoryHint: model.selectedCategoryFilter ?? model.categories.first?.id)
            } label: {
              Label(String(localized: "Create"), systemImage: "plus.circle.fill")
            }
          }
        }
        .alert(
          String(localized: "Persistence notice"),
          isPresented: Binding(
            get: { model.lastErrorDescription != nil },
            set: { if !$0 { model.clearError() } },
          ),
          actions: {
            Button(String(localized: "Dismiss"), role: .cancel) { model.clearError() }
          },
          message: {
            Text(model.lastErrorDescription ?? "")
          },
        )
    }
    .sheet(item: $composing, onDismiss: {}) { surface in
      switch surface {
      case let .compose(hint):
        VaultCredentialComposeSheet(
          homeModel: model,
          mode: .create(initialCategoryHint: hint),
        ) {
          composing = nil
        }
      case let .amend(entry):
        VaultCredentialComposeSheet(
          homeModel: model,
          mode: .modify(entry),
        ) {
          composing = nil
        }
      }
    }
  }

  @ViewBuilder
    private var credentialList: some View {
        Group {
            if model.displayedPasswords.isEmpty {
                if model.isSearching {
                    ContentUnavailableView.search(text: model.searchQuery)
                        .frame(maxHeight: .infinity)
                } else {
                    EmptyVaultHint()
                        .frame(maxHeight: .infinity)
                }
            }
            else {
        List {
          Section {
            ForEach(model.displayedPasswords, id: \.id) { vault in
              HStack(spacing: 0) {
                NavigationLink(value: PassVaultCredentialNavID(credentialId: vault.id)) {
                  VaultCredentialBriefRow(entry: vault)
                }
                .navigationLinkIndicatorVisibility(.hidden)
                .buttonStyle(.plain)

                Menu {
                  Button(String(localized: "Copy secret"), systemImage: "doc.on.doc") {
                    ClipboardFacade.copy(model.plaintext(for: vault), toastHost: copyToastHost)
                  }
                  Button(String(localized: "Edit"), systemImage: "square.and.pencil") {
                    if let latest = model.passwordRow(withId: vault.id) {
                      composing = .amend(latest)
                    }
                    else {
                      composing = .amend(vault)
                    }
                  }
                } label: {
                  Image(systemName: "ellipsis.circle")
                    .foregroundStyle(Color.white.opacity(0.45))
                    .font(.body)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .accessibilityLabel(String(localized: "Quick actions"))
              }
              .contextMenu {
                Button(String(localized: "Copy secret")) {
                  ClipboardFacade.copy(model.plaintext(for: vault), toastHost: copyToastHost)
                }
                Button(String(localized: "Edit")) {
                  if let latest = model.passwordRow(withId: vault.id) {
                    composing = .amend(latest)
                  }
                  else {
                    composing = .amend(vault)
                  }
                }
              }
              .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(String(localized: "Copy secret")) {
                  ClipboardFacade.copy(model.plaintext(for: vault), toastHost: copyToastHost)
                }.tint(.blue)
              }
              .swipeActions(edge: .leading) {
                Button(String(localized: "Edit")) {
                  if let latest = model.passwordRow(withId: vault.id) {
                    composing = .amend(latest)
                  }
                  else {
                    composing = .amend(vault)
                  }
                }.tint(.purple)
              }
            }
          } header: {
            Text(summaryHeader)
              .foregroundStyle(Color.white.opacity(0.55))
              .font(.footnote)
              .textCase(nil)
          }
        }
        .scrollContentBackground(.hidden)
        .navigationDestination(for: PassVaultCredentialNavID.self) { nav in
          if let row = model.passwordRow(withId: nav.credentialId) {
            VaultCredentialInspectionView(entry: row, homeModel: model) {
              if let latest = model.passwordRow(withId: nav.credentialId) {
                composing = .amend(latest)
              }
            }
          }
          else {
            ContentUnavailableView(
              String(localized: "Missing item"),
              systemImage: "exclamationmark.triangle",
              description: Text(String(localized: "This credential may have been removed.")),
            )
          }
        }
      }
    }
    .vaultBackdrop()
  }

  private var summaryHeader: String {
    let count = model.displayedPasswords.count
    if let filterId = model.selectedCategoryFilter {
      let name = model.categories.first(where: { $0.id == filterId })?.name ?? "—"
      return "\(count) · \(name)"
    }
    else {
      return "\(count) · \(String(localized: "All categories"))"
    }
  }

  private var categoryNavTitle: String {
    if let id = model.selectedCategoryFilter {
      return model.categories.first { $0.id == id }?.name ?? "—"
    }
    return String(localized: "All vault")
  }

  private var categoryFilterMenu: some View {
    Menu {
      Button {
        model.selectedCategoryFilter = nil
      } label: {
        HStack {
          Text(String(localized: "All vault"))
          Spacer(minLength: 12)
          if model.selectedCategoryFilter == nil {
            Image(systemName: "checkmark")
          }
        }
      }
      ForEach(model.categories) { cat in
        Button {
          model.selectedCategoryFilter = cat.id
        } label: {
          HStack {
            Text(cat.name)
            Spacer(minLength: 12)
            if model.selectedCategoryFilter == cat.id {
              Image(systemName: "checkmark")
            }
          }
        }
      }
    } label: {
      HStack(spacing: 6) {
        Text(categoryNavTitle)
          .font(.headline)
          .lineLimit(1)
        Image(systemName: "chevron.up.chevron.down")
          .font(.caption.weight(.semibold))
          .foregroundStyle(.secondary)
      }
    }
    .accessibilityLabel(String(localized: "Category filter"))
  }

  private var sortMenu: some View {
    Menu {
      sortRow(.nameAscending, String(localized: "Name ascending"))
      sortRow(.nameDescending, String(localized: "Name descending"))
      sortRow(.dateDescending, String(localized: "Edited · newest"))
      sortRow(.dateAscending, String(localized: "Edited · oldest"))
    } label: {
      Image(systemName: "arrow.up.arrow.down.circle")
    }
    .accessibilityLabel(String(localized: "Sort"))
  }

  private func sortRow(_ mode: HomeViewModel.SortMode, _ title: String) -> some View {
    Button {
      model.sortMode = mode
    } label: {
      HStack {
        Text(title)
        Spacer(minLength: 12)
        if model.sortMode == mode {
          Image(systemName: "checkmark")
        }
      }
    }
  }
}

private struct VaultCredentialBriefRow: View {
  let entry: VaultPasswordRow

  var body: some View {
    HStack(spacing: 16) {
      VaultEntryAvatarView(row: entry)

      VStack(alignment: .leading, spacing: 2) {
        Text(entry.title.isEmpty ? String(localized: "Untitled credential") : entry.title)
          .foregroundStyle(Color.white.opacity(0.95))
          .font(.headline)

        Text(subline(for: entry))
          .foregroundStyle(Color.white.opacity(0.55))
          .font(.subheadline)
          .lineLimit(1)
      }

      Spacer(minLength: 8)
    }
    .padding(.vertical, 8)
  }

  private func subline(for entry: VaultPasswordRow) -> String {
    let site = entry.website.trimmingCharacters(in: .whitespacesAndNewlines)
    if !site.isEmpty { return site }
    return String(localized: "Tap to add a website")
  }
}

private struct EmptyVaultHint: View {
  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "shippingbox.circle")
        .font(.system(size: 56))
        .foregroundStyle(Color.white.opacity(0.45))

      Text(String(localized: "Seed your vault with its first credential to unlock search, analytics, and categories."))
        .multilineTextAlignment(.center)
        .foregroundStyle(Color.white.opacity(0.74))

      Text(String(localized: "Tap · Create · Compose logins wired to recognizable brands or internal sites."))
        .font(.footnote)
        .multilineTextAlignment(.center)
        .foregroundStyle(Color.white.opacity(0.55))
    }
    .frame(maxWidth: .infinity)
    .padding(36)
  }
}
