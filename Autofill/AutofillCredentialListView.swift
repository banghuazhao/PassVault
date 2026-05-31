//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import AuthenticationServices
import SwiftUI

struct AutofillCredentialListView: View {
  let rows: [AutofillStoredPasswordRow]
  let contextSummary: String
  let loadError: String?
  let onCancel: () -> Void
  let onPick: (ASPasswordCredential) -> Void

  @State private var decodeError: String?

  var body: some View {
    NavigationStack {
      Group {
        if let loadError {
          unavailableState(
            title: String(localized: "Vault unavailable"),
            systemImage: "exclamationmark.triangle",
            message: loadError,
          )
        } else if rows.isEmpty {
          ContentUnavailableView {
            Label(String(localized: "No saved passwords"), systemImage: "key.slash")
          } description: {
            Text(
              String(
                localized:
                  "Save logins in PassVault first. Entries whose website matches the sign-in domain are labeled Match."
              )
            )
          }
        } else {
          List(rows) { row in
            Button {
              pick(row)
            } label: {
              VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                  Text(row.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? String(localized: "Untitled")
                    : row.title)
                  .foregroundStyle(Color.primary)
                  if row.isLikelyMatch {
                    Text(String(localized: "Match"))
                      .font(.caption2.weight(.semibold))
                      .padding(.horizontal, 6).padding(.vertical, 2)
                      .foregroundStyle(Color.green.opacity(0.95))
                      .background(Color.green.opacity(0.22))
                      .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                  }
                  Spacer(minLength: 0)
                }
                if row.website.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
                  Text(row.website)
                    .font(.footnote)
                    .foregroundStyle(Color.secondary)
                }
              }
            }
          }
        }
      }
      .navigationTitle(String(localized: "PassVault"))
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(String(localized: "Cancel"), action: onCancel)
        }
      }
    }
    .safeAreaInset(edge: .bottom) {
      if contextSummary.isEmpty == false, loadError == nil {
        Text(contextSummary)
          .font(.footnote)
          .foregroundStyle(Color.secondary)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 16).padding(.vertical, 10)
          .background(.ultraThinMaterial)
      }
    }
    .alert(
      String(localized: "Couldn’t read password"),
      isPresented: Binding(
        get: { decodeError != nil },
        set: { if !$0 { decodeError = nil } },
      ),
    ) {
      Button(String(localized: "Dismiss"), role: .cancel, action: {})
    } message: {
      Text(decodeError ?? "")
    }
  }

  private func pick(_ row: AutofillStoredPasswordRow) {
    do {
      let pwData = try AutofillVaultCrypto.open(row.passwordBlob)
      let password = String(decoding: pwData, as: UTF8.self)
      let trimmedTitle = row.title.trimmingCharacters(in: .whitespacesAndNewlines)
      let user = trimmedTitle.isEmpty ? inferUsernamePlaceholder(from: row.website) : trimmedTitle
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
    } description: {
      Text(message)
    }
  }
}

extension AutofillStoredPasswordRow: Identifiable {}
