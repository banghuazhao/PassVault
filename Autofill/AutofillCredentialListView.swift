//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import AuthenticationServices
import SwiftUI

struct AutofillCredentialListView: View {
  @StateObject var viewModel: AutofillCredentialViewModel
  let contextSummary: String
  let onCancel: () -> Void
  let onPick: (ASPasswordCredential) -> Void

  @State private var decodeError: String?

  private var suggestedRows: [AutofillStoredPasswordRow] {
    viewModel.rows.filter { $0.isLikelyMatch }
  }

  private var otherRows: [AutofillStoredPasswordRow] {
    viewModel.rows.filter { !$0.isLikelyMatch }
  }

  var body: some View {
    NavigationStack {
      ZStack {
        AutofillPalette.backdropTop.ignoresSafeArea()
        
        Group {
          if let loadError = viewModel.loadError {
            unavailableState(
              title: String(localized: "Vault unavailable"),
              systemImage: "exclamationmark.triangle",
              message: loadError
            )
          } else if viewModel.rows.isEmpty {
            ContentUnavailableView {
              Label(String(localized: "No saved passwords"), systemImage: "key.slash")
                .foregroundStyle(.white)
            } description: {
              Text(
                String(
                  localized:
                    "Save logins in PassVault first. Entries whose website matches the sign-in domain are labeled Match."
                )
              )
              .foregroundStyle(.white.opacity(0.6))
            }
          } else {
            List {
              if !suggestedRows.isEmpty {
                Section {
                  ForEach(suggestedRows) { row in
                    rowButton(row)
                  }
                } header: {
                  Text(String(localized: "Suggested"))
                    .foregroundStyle(.white.opacity(0.5))
                }
              }

              if !otherRows.isEmpty {
                Section {
                  ForEach(otherRows) { row in
                    rowButton(row)
                  }
                } header: {
                  Text(String(localized: "All passwords"))
                    .foregroundStyle(.white.opacity(0.5))
                }
              }
            }
            .scrollContentBackground(.hidden)
          }
        }
      }
      .navigationTitle(String(localized: "PassVault"))
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(String(localized: "Cancel"), action: onCancel)
            .foregroundStyle(.white)
        }
        ToolbarItem(placement: .primaryAction) {
          NavigationLink {
            AutofillCredentialCreateView(
              initialWebsite: contextSummary,
              onCreated: {
                viewModel.load()
              }
            )
          } label: {
            Image(systemName: "plus.circle.fill")
              .font(.title3)
              .foregroundStyle(.white)
          }
        }
      }
      .toolbarBackground(AutofillPalette.backdropTop, for: .navigationBar)
      .toolbarColorScheme(.dark, for: .navigationBar)
    }
    .safeAreaInset(edge: .bottom) {
      if contextSummary.isEmpty == false, viewModel.loadError == nil {
        Text(contextSummary)
          .font(.footnote.weight(.medium))
          .foregroundStyle(.white.opacity(0.5))
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 16).padding(.vertical, 10)
          .background(.ultraThinMaterial)
      }
    }
    .alert(
      String(localized: "Couldn’t read password"),
      isPresented: Binding(
        get: { decodeError != nil },
        set: { if !$0 { decodeError = nil } }
      )
    ) {
      Button(String(localized: "Dismiss"), role: .cancel, action: {})
    } message: {
      Text(decodeError ?? "")
    }
    .preferredColorScheme(.dark)
  }

  @ViewBuilder
  private func rowButton(_ row: AutofillStoredPasswordRow) -> some View {
    Button {
      pick(row)
    } label: {
      HStack(spacing: 14) {
        AutofillEntryAvatarView(title: row.title, website: row.website, isMatch: row.isLikelyMatch)

        VStack(alignment: .leading, spacing: 4) {
          HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(row.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
              ? String(localized: "Untitled")
              : row.title)
            .font(.headline)
            .foregroundStyle(.white.opacity(0.9))
            
            if row.isLikelyMatch {
              Text(String(localized: "Match"))
                .font(.system(size: 10, weight: .bold))
                .padding(.horizontal, 5).padding(.vertical, 1)
                .foregroundStyle(.green)
                .background(.green.opacity(0.2))
                .clipShape(Capsule())
            }
          }
          
          if row.website.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            Text(row.website)
              .font(.subheadline)
              .foregroundStyle(.white.opacity(0.5))
          }
        }
        
        Spacer(minLength: 0)
        
        Image(systemName: "chevron.right")
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white.opacity(0.2))
      }
      .padding(.vertical, 4)
    }
    .listRowBackground(AutofillPalette.elevatedCard)
  }

  private func pick(_ row: AutofillStoredPasswordRow) {
    do {
      let pwData = try AutofillVaultCrypto.open(row.passwordBlob)
      let password = String(decoding: pwData, as: UTF8.self)
      let trimmedTitle = row.title.trimmingCharacters(in: .whitespacesAndNewlines)
      let user = trimmedTitle.isEmpty ? inferUsernamePlaceholder(from: row.website) : trimmedTitle
      
      let feedback = UINotificationFeedbackGenerator()
      feedback.notificationOccurred(.success)
      
      onPick(ASPasswordCredential(user: user, password: password))
    } catch {
      decodeError = error.localizedDescription
    }
  }

  private func inferUsernamePlaceholder(from website: String) -> String {
    let w = website.trimmingCharacters(in: .whitespacesAndNewlines)
    if let url = URL(string: w), let host = url.host { return host }
    if let url = URL(string: "https://\(w)"), let host = url.host { return host }
    return String(localized: "Account")
  }

  private func unavailableState(title: String, systemImage: String, message: String) -> some View {
    ContentUnavailableView {
      Label(title, systemImage: systemImage)
        .foregroundStyle(.white)
    } description: {
      Text(message)
        .foregroundStyle(.white.opacity(0.6))
    }
  }
}

extension AutofillStoredPasswordRow: Identifiable {}
