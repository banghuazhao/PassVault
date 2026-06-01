//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import UIKit

enum Haptics {
  static func success() {
    let generator = UINotificationFeedbackGenerator()
    generator.notificationOccurred(.success)
  }

  static func warning() {
    let generator = UINotificationFeedbackGenerator()
    generator.notificationOccurred(.warning)
  }

  static func selection() {
    let generator = UISelectionFeedbackGenerator()
    generator.selectionChanged()
  }
}
