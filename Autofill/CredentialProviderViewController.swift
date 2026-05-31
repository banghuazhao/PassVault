//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import AuthenticationServices
import SwiftUI
import UIKit

final class CredentialProviderViewController: ASCredentialProviderViewController {

  override func prepareCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
    detachChildViewControllers()

    let hosts = Self.normalizedHosts(from: serviceIdentifiers)
    let loadResult = Result(catching: { try AutofillDatabase.fetchPasswordRows(forMatchingHosts: hosts) })
    let rows: [AutofillStoredPasswordRow]
    let loadError: String?
    switch loadResult {
    case .success(let fetched):
      rows = fetched
      loadError = nil
    case .failure(let error):
      rows = []
      loadError = error.localizedDescription
    }

    let summary = Self.contextSummary(from: serviceIdentifiers)
    let root = AutofillCredentialListView(
      rows: rows,
      contextSummary: summary,
      loadError: loadError,
      onCancel: { [weak self] in
        guard let context = self?.extensionContext else { return }
        context.cancelRequest(
          withError: NSError(
            domain: ASExtensionErrorDomain,
            code: ASExtensionError.userCanceled.rawValue,
          ))
      },
      onPick: { [weak self] cred in
        self?.extensionContext.completeRequest(withSelectedCredential: cred, completionHandler: nil)
      },
    )

    let hostController = UIHostingController(rootView: root)
    embedFullScreen(hostController)
  }

  private func detachChildViewControllers() {
    for child in children {
      child.willMove(toParent: nil)
      child.view.removeFromSuperview()
      child.removeFromParent()
    }
  }

  private func embedFullScreen(_ child: UIViewController) {
    addChild(child)
    child.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(child.view)
    NSLayoutConstraint.activate([
      child.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      child.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      child.view.topAnchor.constraint(equalTo: view.topAnchor),
      child.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    child.didMove(toParent: self)
  }

  private static func normalizedHosts(from identifiers: [ASCredentialServiceIdentifier]) -> Set<String> {
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

  private static func contextSummary(from identifiers: [ASCredentialServiceIdentifier]) -> String {
    guard let first = identifiers.first else { return "" }
    switch first.type {
    case .domain:
      return first.identifier
    case .URL:
      return URL(string: first.identifier)?.host ?? first.identifier
    @unknown default:
      return first.identifier
    }
  }
}
