//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct CategoriesPaneView: View {
  @Bindable var categoriesVm: CategoriesViewModel
  @Bindable var homeVm: HomeViewModel
  @Environment(\.copyToastHost) private var copyToastHost

  @State private var newTray = false
  @State private var newName = ""
  @State private var newIcon = "folder.fill"
  @State private var renameSubject: CategoryRow?
  @State private var deleteSubject: CategoryRow?

  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 152), spacing: 14)], spacing: 14) {
          ForEach(categoriesVm.categories) { cat in
            NavigationLink {
              CategoryShelfStrip(categoryId: cat.id, categoriesVm: categoriesVm, homeVm: homeVm)
            } label: {
              CategoryTileCard(category: cat, count: categoriesVm.passwordCount(for: cat.id))
            }
            .navigationLinkIndicatorVisibility(.hidden)
            .contextMenu {
              Button(String(localized: "Rename folder")) {
                renameSubject = cat
              }
              Button(String(localized: "Delete folder"), role: .destructive) {
                deleteSubject = cat
              }
            }
          }
        }
        .padding(18)
      }
      .vaultBackdrop()
      .navigationTitle(String(localized: "Categories"))
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            newTray = true
          } label: {
            Image(systemName: "plus.circle.fill")
          }
        }
      }
      .sheet(isPresented: $newTray) {
        NavigationStack {
          Form {
            TextField(String(localized: "Folder name"), text: $newName)
            Section(String(localized: "Icon")) {
              CategoryFolderIconPicker(selectedSymbol: $newIcon)
            }
          }
          .navigationTitle(String(localized: "New folder"))
          .toolbar {
            ToolbarItem(placement: .cancellationAction) {
              Button(String(localized: "Cancel")) {
                newTray = false
              }
            }
            ToolbarItem(placement: .confirmationAction) {
              Button(String(localized: "Add")) {
                Task {
                  await categoriesVm.insertCategory(
                    name: newName.isEmpty ? String(localized: "Untitled") : newName,
                    iconSFName: newIcon,
                  )
                  newName = ""
                  newIcon = "folder.fill"
                  newTray = false
                }
              }
            }
          }
        }
      }
      .onChange(of: newTray) { _, isOpen in
        if isOpen {
          newName = ""
          newIcon = "folder.fill"
        }
      }
      .sheet(item: $renameSubject) { row in
        RenameCategoryOverlay(category: row, categoriesVm: categoriesVm)
      }
      .confirmationDialog(
        String(localized: "Migrate every password before removing this folder."),
        isPresented: Binding(
          get: { deleteSubject != nil },
          set: { flag in if !flag { deleteSubject = nil } },
        ),
        titleVisibility: .visible,
      ) {
        if let victim = deleteSubject {
          let exits = categoriesVm.categories.filter { $0.id != victim.id }
          if exits.isEmpty {
            Button(String(localized: "OK")) {
              deleteSubject = nil
            }
          } else {
            ForEach(exits) { dest in
              Button(dest.name) {
                Task {
                  await categoriesVm.deleteCategory(victim, migratingPasswordsTo: dest.id)
                  deleteSubject = nil
                }
              }
            }
            Button(String(localized: "Cancel"), role: .cancel) {
              deleteSubject = nil
            }
          }
        }
      }
      .alert(
        String(localized: "Vault notice"),
        isPresented: Binding(
          get: { categoriesVm.lastErrorDescription != nil },
          set: { flag in if !flag { categoriesVm.lastErrorDescription = nil } },
        ),
        actions: {
          Button(String(localized: "Dismiss"), role: .cancel) {
            categoriesVm.lastErrorDescription = nil
          }
        },
        message: {
          Text(categoriesVm.lastErrorDescription ?? "")
        },
      )
    }
  }
}

private struct RenameCategoryOverlay: View {
  let category: CategoryRow
  @Bindable var categoriesVm: CategoriesViewModel
  @Environment(\.dismiss) private var dismiss
  @State private var name: String
  @State private var icon: String

  init(category: CategoryRow, categoriesVm: CategoriesViewModel) {
    self.category = category
    self.categoriesVm = categoriesVm
    _name = State(initialValue: category.name)
    _icon = State(initialValue: category.iconSFName)
  }

  var body: some View {
    NavigationStack {
      Form {
        TextField(String(localized: "Folder name"), text: $name)
        Section(String(localized: "Icon")) {
          CategoryFolderIconPicker(selectedSymbol: $icon)
        }
      }
      .navigationTitle(String(localized: "Rename folder"))
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(String(localized: "Cancel")) {
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button(String(localized: "Save")) {
            Task {
              await categoriesVm.updateCategory(name: name, iconSFName: icon, for: category)
              dismiss()
            }
          }
        }
      }
    }
  }
}

private struct CategoryTileCard: View {
  let category: CategoryRow
  let count: Int

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Image(systemName: category.iconSFName)
        .font(.title2.weight(.semibold))
        .foregroundStyle(Color.white.opacity(0.92))
        .frame(maxWidth: .infinity, alignment: .leading)
      Text(category.name)
        .foregroundStyle(Color.white.opacity(0.94))
        .font(.headline)
      Text(String(localized: "\(count) items"))
        .font(.caption.weight(.medium))
        .foregroundStyle(Color.white.opacity(0.55))
      Spacer(minLength: 0)
    }
    .padding(14)
    .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
    .vaultCard()
  }
}

struct CategoryShelfStrip: View {
  let categoryId: Int
  @Bindable var categoriesVm: CategoriesViewModel
  @Bindable var homeVm: HomeViewModel
  @Environment(\.copyToastHost) private var copyToastHost

  @State private var composing: VaultComposerSurface?

  private var payloads: [VaultPasswordRow] {
    homeVm.allVaultRows
      .filter { $0.categoryId == categoryId }
      .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
  }

  private var cohort: CategoryRow? {
    categoriesVm.categories.first { $0.id == categoryId }
  }

  var body: some View {
    Group {
      if payloads.isEmpty {
        ContentUnavailableView(
          String(localized: "Empty folder"),
          systemImage: "tray",
          description: Text(String(localized: "Create a credential pinned to this category.")),
        )
        .vaultBackdrop()
      } else {
        List {
          Section {
            ForEach(payloads, id: \.id) { row in
              HStack(spacing: 0) {
                NavigationLink(value: row.id) {
                  HStack(spacing: 12) {
                    VaultEntryAvatarView(row: row)
                    VStack(alignment: .leading, spacing: 4) {
                      Text(row.title.isEmpty ? String(localized: "Untitled credential") : row.title)
                      Text(rowSubtitle(row))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 8)
                  }
                  .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                .navigationLinkIndicatorVisibility(.hidden)

                Menu {
                  Button(String(localized: "Copy secret"), systemImage: "doc.on.doc") {
                    ClipboardFacade.copy(homeVm.plaintext(for: row), toastHost: copyToastHost)
                  }
                  Button(String(localized: "Edit"), systemImage: "square.and.pencil") {
                    if let latest = homeVm.passwordRow(withId: row.id) {
                      composing = .amend(latest)
                    }
                    else {
                      composing = .amend(row)
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
            }
          }
        }
        .scrollContentBackground(.hidden)
        .vaultBackdrop()
      }
    }
    .navigationTitle(cohort?.name ?? String(localized: "Folder"))
    .navigationDestination(for: Int.self) { id in
      if let row = homeVm.passwordRow(withId: id) {
        VaultCredentialInspectionView(entry: row, homeModel: homeVm) {
          if let latest = homeVm.passwordRow(withId: id) {
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
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          composing = .compose(categoryHint: categoryId)
        } label: {
          Label(String(localized: "Create"), systemImage: "plus.circle.fill")
        }
      }
    }
    .sheet(item: $composing, onDismiss: {}) { surface in
      switch surface {
      case let .compose(hint):
        VaultCredentialComposeSheet(homeModel: homeVm, mode: .create(initialCategoryHint: hint)) {
          composing = nil
        }

      case let .amend(entry):
        VaultCredentialComposeSheet(homeModel: homeVm, mode: .modify(entry)) {
          composing = nil
        }
      }
    }
  }

  private func rowSubtitle(_ row: VaultPasswordRow) -> String {
    let site = row.website.trimmingCharacters(in: .whitespacesAndNewlines)
    if !site.isEmpty { return site }
    return String(localized: "Tap to add a website")
  }
}
