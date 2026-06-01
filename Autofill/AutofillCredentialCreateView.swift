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
  @State private var notes = ""
  @State private var customIconSFName = ""
  @State private var cadence = 0
  
  @State private var error: String?
  @State private var isSaving = false
  @State private var passwordVisible = false
  @State private var showGenerator = false

  var body: some View {
    ZStack {
      AutofillPalette.backdropTop.ignoresSafeArea()
      
      Form {
        Section {
          iconHero.vaultRowStyle()
        }
        
        Section {
          TextField(String(localized: "Title"), text: $title)
          
          HStack {
            if passwordVisible {
              TextField(String(localized: "Password"), text: $password)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            } else {
              SecureField(String(localized: "Password"), text: $password)
            }
            
            Button {
              passwordVisible.toggle()
            } label: {
              Image(systemName: passwordVisible ? "eye.slash" : "eye")
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
          }
          
          Button {
            showGenerator = true
          } label: {
            Label(String(localized: "Password generator"), systemImage: "wand.and.stars")
          }
          
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
        
        Section(String(localized: "Notes")) {
          TextField(String(localized: "Notes"), text: $notes, axis: .vertical)
            .lineLimit(3...10)
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
        }
      }
      .scrollContentBackground(.hidden)
    }
    .navigationTitle(String(localized: "New credential"))
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .confirmationAction) {
        Button(String(localized: "Save")) {
          save()
        }
        .disabled(title.isEmpty || password.isEmpty || isSaving)
        .foregroundStyle(.white)
      }
    }
    .toolbarBackground(AutofillPalette.backdropTop, for: .navigationBar)
    .toolbarColorScheme(.dark, for: .navigationBar)
    .task {
      loadCategories()
    }
    .onAppear {
      if website.isEmpty {
          website = initialWebsite
      }
    }
    .sheet(isPresented: $showGenerator) {
      AutofillPasswordGeneratorSheet(password: $password)
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
    .preferredColorScheme(.dark)
  }

  private var iconHero: some View {
    VStack(spacing: 12) {
      ZStack {
        Circle()
          .fill(Color.white.opacity(0.1))
        
        if let digits = titlePreview(from: title) {
          Text(digits)
            .font(.system(size: 28, weight: .semibold, design: .rounded))
            .foregroundStyle(.white.opacity(0.8))
        } else {
          Image(systemName: "key.fill")
            .font(.system(size: 24))
            .foregroundStyle(.white.opacity(0.6))
        }
      }
      .frame(width: 80, height: 80)
      .overlay(
          Circle()
              .stroke(Color.white.opacity(0.1), lineWidth: 1)
      )
      
      Text(title.isEmpty ? String(localized: "Untitled") : title)
        .font(.headline)
        .foregroundStyle(.white.opacity(0.9))
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 20)
  }

  private func titlePreview(from title: String) -> String? {
    let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !t.isEmpty else { return nil }
    return String(t.prefix(2)).uppercased()
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
    let reminderMonths = cadence == 0 ? nil : cadence
    do {
      try AutofillDatabase.insertPassword(
        categoryId: selectedCategoryId,
        title: title,
        password: password,
        website: website,
        notes: notes,
        customIconSFName: customIconSFName.isEmpty ? nil : customIconSFName,
        reminderMonths: reminderMonths
      )
      
      let feedback = UINotificationFeedbackGenerator()
      feedback.notificationOccurred(.success)
      
      onCreated()
      dismiss()
    } catch {
      self.error = error.localizedDescription
      isSaving = false
    }
  }
}

private extension View {
  func vaultRowStyle() -> some View {
    self
      .listRowBackground(Color.clear)
      .listRowInsets(EdgeInsets())
  }
}
