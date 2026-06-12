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
          ForEach(categoriesVm.categories, id: \.id) { cat in
            NavigationLink(value: PassVaultCategoryShelfNavID(categoryId: cat.id)) {
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
      .navigationDestination(for: PassVaultCategoryShelfNavID.self) { shelf in
        CategoryShelfStrip(
          categoryId: shelf.categoryId,
          categoriesVm: categoriesVm,
          homeVm: homeVm,
        )
      }
      .navigationTitle(String(localized: "Categories"))
      .navigationBarTitleDisplayMode(.inline)
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
                  Haptics.success()
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
        String(localized: "Remove folder"),
        isPresented: Binding(
          get: { deleteSubject != nil },
          set: { flag in if !flag { deleteSubject = nil } },
        ),
        titleVisibility: .visible,
      ) {
        if let victim = deleteSubject {
          let count = categoriesVm.passwordCount(for: victim.id)
          let exits = categoriesVm.categories.filter { $0.id != victim.id }
          
          if count > 0 {
            if !exits.isEmpty {
              Menu(String(localized: "Migrate and delete folder")) {
                ForEach(exits) { dest in
                  Button(dest.name) {
                    Task {
                      await categoriesVm.deleteCategory(victim, migratingPasswordsTo: dest.id)
                      deleteSubject = nil
                    }
                  }
                }
              }
            }
            
            Button(String(localized: "Delete folder and all \(count) items"), role: .destructive) {
              Task {
                await categoriesVm.deleteCategoryAndPasswords(victim)
                deleteSubject = nil
              }
            }
          } else {
            Button(String(localized: "Delete empty folder"), role: .destructive) {
              Task {
                await categoriesVm.deleteCategoryAndPasswords(victim)
                deleteSubject = nil
              }
            }
          }
          
          Button(String(localized: "Cancel"), role: .cancel) {
            deleteSubject = nil
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
              Haptics.success()
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
  @State private var confirmEmpty = false
  @State private var showMigrate = false

  private var payloads: [VaultPasswordRow] {
    homeVm.allVaultRows
      .filter { $0.categoryId == categoryId }
      .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
  }

  private var cohort: CategoryRow? {
    categoriesVm.categories.first { $0.id == categoryId }
  }

  private var otherCategories: [CategoryRow] {
    categoriesVm.categories.filter { $0.id != categoryId }
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
                NavigationLink(value: PassVaultCredentialNavID(credentialId: row.id)) {
                  HStack(spacing: 12) {
                    VaultEntryAvatarView(row: row)
                    VStack(alignment: .leading, spacing: 4) {
                      Text(row.title.isEmpty ? String(localized: "Untitled credential") : row.title)
                      
                      let site = row.website.trimmingCharacters(in: .whitespacesAndNewlines)
                      if !site.isEmpty {
                        Text(site)
                          .font(.caption)
                          .foregroundStyle(.secondary)
                          .lineLimit(1)
                      }
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
    .navigationBarTitleDisplayMode(.inline)
    .navigationDestination(for: PassVaultCredentialNavID.self) { nav in
      if let row = homeVm.passwordRow(withId: nav.credentialId) {
        VaultCredentialInspectionView(entry: row, homeModel: homeVm) {
          if let latest = homeVm.passwordRow(withId: nav.credentialId) {
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
        HStack(spacing: 16) {
          if !payloads.isEmpty {
            Menu {
              if !otherCategories.isEmpty {
                Button(String(localized: "Migrate all to..."), systemImage: "arrow.right.square") {
                  showMigrate = true
                }
              }
              
              Button(role: .destructive) {
                confirmEmpty = true
              } label: {
                Label(String(localized: "Empty folder"), systemImage: "trash")
              }
            } label: {
              Image(systemName: "folder.badge.minus")
            }
          }
          
          Button {
            composing = .compose(categoryHint: categoryId)
          } label: {
            Label(String(localized: "Create"), systemImage: "plus.circle.fill")
          }
        }
      }
    }
    .confirmationDialog(
        String(localized: "Migrate items to..."),
        isPresented: $showMigrate,
        titleVisibility: .visible
    ) {
        ForEach(otherCategories) { dest in
            Button(dest.name) {
                Task {
                    await categoriesVm.movePasswordsInCategory(from: categoryId, to: dest.id)
                    Haptics.success()
                }
            }
        }
        Button(String(localized: "Cancel"), role: .cancel) {}
    }
    .alert(
        String(localized: "Empty this folder?"),
        isPresented: $confirmEmpty,
        actions: {
            Button(String(localized: "Cancel"), role: .cancel) {}
            Button(String(localized: "Empty all \(payloads.count) items"), role: .destructive) {
                Task {
                    await categoriesVm.deletePasswordsInCategory(categoryId: categoryId)
                    Haptics.warning()
                }
            }
        },
        message: {
            Text(String(localized: "This will permanently remove every credential in this folder."))
        }
    )
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
}
