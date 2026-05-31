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

    let summary = Self.contextSummary(from: serviceIdentifiers)
    let viewModel = AutofillCredentialViewModel(serviceIdentifiers: serviceIdentifiers)
    let root = AutofillCredentialListView(
      viewModel: viewModel,
      contextSummary: summary,
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
