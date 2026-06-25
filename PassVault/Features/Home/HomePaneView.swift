//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct HomePaneView: View {
  @Bindable private var model: HomeViewModel
  @State private var composing: VaultComposerSurface?
  @State private var bannerHeight: CGFloat = 50
  @Environment(\.copyToastHost) private var copyToastHost

  init(model: HomeViewModel) {
    self.model = model
  }

  var body: some View {
    NavigationStack {
      ZStack {
        VaultPalette.backdropTop.ignoresSafeArea()

        VStack(spacing: 0) {
          credentialList
            .searchable(text: $model.searchQuery, prompt: String(localized: "Search title or site"))

          BannerAdView(adUnitID: AdConfig.bannerAdUnitID, adHeight: $bannerHeight)
            .frame(height: bannerHeight)
            .background(Color.black.opacity(0.85))
        }
      }
      .navigationTitle(String(localized: "Vault"))
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          categoryFilterPicker
        }
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            composing = .compose(categoryHint: model.selectedCategoryFilter)
          } label: {
            Label(String(localized: "Create"), systemImage: "plus.circle.fill")
              .font(.title3)
          }
        }
      }
    }
    .sheet(item: $composing, onDismiss: {}) { surface in
      switch surface {
      case let .compose(hint):
        VaultCredentialComposeSheet(homeModel: model, mode: .create(initialCategoryHint: hint)) {
          composing = nil
        }

      case let .amend(entry):
        VaultCredentialComposeSheet(homeModel: model, mode: .modify(entry)) {
          composing = nil
        }
      }
    }
  }

  @ViewBuilder
  private var categoryFilterPicker: some View {
    Menu {
      Button {
        model.selectedCategoryFilter = nil
      } label: {
        HStack {
          Text(String(localized: "All categories"))
          if model.selectedCategoryFilter == nil {
            Image(systemName: "checkmark")
          }
        }
      }

      Divider()

      ForEach(model.categories) { cat in
        Button {
          model.selectedCategoryFilter = cat.id
        } label: {
          HStack {
            Label(cat.name, systemImage: cat.iconSFName)
            if model.selectedCategoryFilter == cat.id {
              Image(systemName: "checkmark")
            }
          }
        }
      }
    } label: {
      let active = model.categories.first { $0.id == model.selectedCategoryFilter }
      Label(
        active?.name ?? String(localized: "All"),
        systemImage: active?.iconSFName ?? "line.3.horizontal.decrease.circle"
      )
      .font(.subheadline.weight(.medium))
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
      } else {
        List {
          Section {
            ForEach(model.displayedPasswords, id: \.id) { vault in
              HStack(spacing: 0) {
                NavigationLink(value: PassVaultCredentialNavID(credentialId: vault.id)) {
                  VaultCredentialBriefRow(entry: vault)
                }
                .buttonStyle(.plain)
                .navigationLinkIndicatorVisibility(.hidden)

                Menu {
                  Button(String(localized: "Copy secret"), systemImage: "doc.on.doc") {
                    ClipboardFacade.copy(model.plaintext(for: vault), toastHost: copyToastHost)
                  }
                  Button(String(localized: "Edit"), systemImage: "square.and.pencil") {
                    if let latest = model.passwordRow(withId: vault.id) {
                      composing = .amend(latest)
                    } else {
                      composing = .amend(vault)
                    }
                  }
                  Button(role: .destructive) {
                    Task {
                      await model.deletePassword(vault)
                    }
                  } label: {
                    Label(String(localized: "Delete"), systemImage: "trash")
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
          } else {
            ContentUnavailableView(
              String(localized: "Missing item"),
              systemImage: "exclamationmark.triangle",
              description: Text(String(localized: "This credential may have been removed.")),
            )
          }
        }
      }
    }
  }

  private var summaryHeader: String {
    let count = model.displayedPasswords.count
    if model.isSearching {
      return String(localized: "\(count) found")
    }
    return count == 1 ? String(localized: "1 item stored") : String(localized: "\(count) items stored")
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

        let site = entry.website.trimmingCharacters(in: .whitespacesAndNewlines)
        if !site.isEmpty {
          Text(site)
            .foregroundStyle(Color.white.opacity(0.55))
            .font(.subheadline)
            .lineLimit(1)
        }
      }

      Spacer(minLength: 8)
    }
    .padding(.vertical, 8)
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
