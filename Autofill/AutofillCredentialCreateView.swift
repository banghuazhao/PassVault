//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct AutofillCredentialCreateView: View {
  let initialWebsite: String
  let onCreated: () -> Void

  @Environment(\.dismiss) private var dismiss
  @State private var categories: [AutofillCategoryRow] = []
  @State private var selectedCategoryId: Int64 = 0
  @State private var title = ""
  @State private var password = ""
  @State private var website = ""
  @State private var error: String?
  @State private var isSaving = false

  var body: some View {
    Form {
      Section {
        TextField(String(localized: "Title"), text: $title)
        SecureField(String(localized: "Password"), text: $password)
        TextField(String(localized: "Website"), text: $website)
          .textInputAutocapitalization(.never)
          .keyboardType(.URL)
          .autocorrectionDisabled()
      }

      Section(String(localized: "Category")) {
        Picker(String(localized: "Folder"), selection: $selectedCategoryId) {
          ForEach(categories) { cat in
            Text(cat.name).tag(cat.id)
          }
        }
      }
    }
    .navigationTitle(String(localized: "New credential"))
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button(String(localized: "Save")) {
          save()
        }
        .disabled(title.isEmpty || password.isEmpty || isSaving)
      }
    }
    .task {
      loadCategories()
    }
    .onAppear {
      website = initialWebsite
      if title.isEmpty {
          title = initialWebsite
      }
    }
    .alert(
      String(localized: "Error"),
      isPresented: Binding(
        get: { error != nil },
        set: { if !$0 { error = nil } }
      )
    ) {
      Button(String(localized: "OK"), role: .cancel) {}
    } message: {
      if let error {
        Text(error)
      }
    }
  }

  private func loadCategories() {
    do {
      categories = try AutofillDatabase.fetchCategories()
      if let first = categories.first {
        selectedCategoryId = first.id
      }
    } catch {
      self.error = error.localizedDescription
    }
  }

  private func save() {
    isSaving = true
    do {
      try AutofillDatabase.insertPassword(
        categoryId: selectedCategoryId,
        title: title,
        password: password,
        website: website
      )
      onCreated()
      dismiss()
    } catch {
      self.error = error.localizedDescription
      isSaving = false
    }
  }
}
