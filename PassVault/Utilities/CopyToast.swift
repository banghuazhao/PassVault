//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Observation
import SwiftUI

private enum CopyToastHostKey: EnvironmentKey {
  static let defaultValue: CopyToastHost? = nil
}

extension EnvironmentValues {
  var copyToastHost: CopyToastHost? {
    get { self[CopyToastHostKey.self] }
    set { self[CopyToastHostKey.self] = newValue }
  }
}

/// Shows brief confirmation after clipboard copy (toast-style banner).
@Observable
@MainActor
final class CopyToastHost {
  var message: String?
  private var dismissWorkItem: DispatchWorkItem?

  func show(_ text: String) {
    dismissWorkItem?.cancel()
    message = text
    let work = DispatchWorkItem { [weak self] in
      self?.message = nil
    }
    dismissWorkItem = work
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8, execute: work)
  }
}

struct CopyToastOverlay: View {
  @Bindable var host: CopyToastHost

  var body: some View {
    ZStack {
      if let message = host.message {
        Text(message)
          .font(.subheadline.weight(.semibold))
          .foregroundStyle(Color.white.opacity(0.95))
          .padding(.horizontal, 18)
          .padding(.vertical, 12)
          .background(.ultraThinMaterial, in: Capsule())
          .shadow(color: .black.opacity(0.35), radius: 12, y: 4)
          .transition(.move(edge: .bottom).combined(with: .opacity))
          .padding(.bottom, 12)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    .padding(.bottom, 52)
    .allowsHitTesting(false)
    .animation(.spring(response: 0.38, dampingFraction: 0.82), value: host.message)
  }
}
