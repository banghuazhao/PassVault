//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import UIKit

enum ClipboardFacade {
  @MainActor static func copy(
    _ text: String,
    toastHost: CopyToastHost? = nil,
    confirmation: String? = nil,
  ) {
    UIPasteboard.general.string = text
    Haptics.success()
    guard let toastHost else { return }
    toastHost.show(confirmation ?? String(localized: "Copied"))
  }
}
