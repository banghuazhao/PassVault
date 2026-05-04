//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI
import UIKit

/// Presents share / save dialogs for transient export files from SwiftUI sheets.
struct IosActivityBridge: UIViewControllerRepresentable {

  var activityItems: [Any]

  func makeUIViewController(context: Context) -> UIActivityViewController {

    UIActivityViewController(activityItems: activityItems, applicationActivities: nil)

  }

  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}

}
