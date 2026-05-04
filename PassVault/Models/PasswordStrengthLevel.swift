//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

enum PasswordStrengthLevel: String {
  case weak
  case medium
  case strong

  var displayTitle: String {
    switch self {
    case .weak: String(localized: "Weak")
    case .medium: String(localized: "Medium")
    case .strong: String(localized: "Strong")
    }
  }

  /// Short label used in the generator banner (e.g. “Strong password”).
  var passwordBannerTitle: String {
    switch self {
    case .weak: String(localized: "Weak password")
    case .medium: String(localized: "Medium password")
    case .strong: String(localized: "Strong password")
    }
  }

  var tint: Color {
    switch self {
    case .weak: .orange
    case .medium: .yellow
    case .strong: .green
    }
  }
}

enum PasswordStrengthEvaluator {

  nonisolated static func evaluate(password: String) -> PasswordStrengthLevel {
    guard !password.isEmpty else { return .weak }

    let length = password.count
    let hasUpper = password.contains { $0.isUppercase }
    let hasLower = password.contains { $0.isLowercase }
    let hasDigit = password.contains(where: \.isNumber)
    let hasSymbol = password.contains(where: {
      "!@#$%^&*()_-+=[]{}/?.,;:<>|\\~`'\"¡§•£¥€¶ç".contains($0)
    })

    var classes = 0
    if hasUpper { classes += 1 }
    if hasLower { classes += 1 }
    if hasDigit { classes += 1 }
    if hasSymbol { classes += 1 }

    if length >= 16, classes >= 3 { return .strong }
    if length >= 12, classes >= 3 { return .strong }
    if length >= 10, classes >= 2 { return .medium }
    if length >= 8, classes >= 2 { return .medium }
    if length <= 7 { return .weak }
    return .medium
  }
}
