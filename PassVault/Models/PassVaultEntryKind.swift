//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation

enum PassVaultEntryKind: String, CaseIterable, Identifiable {
  case login
  case wifi
  case bank
  case identity
  case secureNote
  case other

  var id: String { rawValue }

  var displayTitle: String {
    switch self {
    case .login: "Login"
    case .wifi: "Wi‑Fi"
    case .bank: "Bank"
    case .identity: "Identity"
    case .secureNote: "Secure note"
    case .other: "Other"
    }
  }

  var defaultIcon: String {
    switch self {
    case .login: "person.crop.circle"
    case .wifi: "wifi"
    case .bank: "creditcard"
    case .identity: "person.text.rectangle"
    case .secureNote: "note.text"
    case .other: "key.horizontal"
    }
  }
}
