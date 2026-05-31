//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import AuthenticationServices
import Combine
import SwiftUI

@MainActor
final class AutofillCredentialViewModel: ObservableObject {
  @Published var rows: [AutofillStoredPasswordRow] = []
  @Published var loadError: String?

  private let serviceIdentifiers: [ASCredentialServiceIdentifier]

  init(serviceIdentifiers: [ASCredentialServiceIdentifier]) {
    self.serviceIdentifiers = serviceIdentifiers
    load()
  }

  func load() {
    let hosts = normalizedHosts(from: serviceIdentifiers)
    do {
      rows = try AutofillDatabase.fetchPasswordRows(forMatchingHosts: hosts)
      loadError = nil
    } catch {
      rows = []
      loadError = error.localizedDescription
    }
  }

  private func normalizedHosts(from identifiers: [ASCredentialServiceIdentifier]) -> Set<String> {
    var hosts: Set<String> = []
    for id in identifiers {
      switch id.type {
      case .domain:
        hosts.insert(id.identifier.lowercased())
      case .URL:
        if let url = URL(string: id.identifier), let host = url.host?.lowercased() {
          hosts.insert(host)
        }
      @unknown default:
        break
      }
    }
    return hosts
  }
}
