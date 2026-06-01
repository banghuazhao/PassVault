//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI

struct AutofillEntryAvatarView: View {
  let title: String
  let website: String
  let isMatch: Bool

  var body: some View {
    ZStack {
      Circle()
        .fill(isMatch ? Color.green.opacity(0.15) : Color.white.opacity(0.1))
      
      if let icon = iconText {
        Text(icon)
          .font(.system(size: 14, weight: .bold, design: .rounded))
          .foregroundStyle(isMatch ? .green : .white.opacity(0.8))
      } else {
        Image(systemName: "key.fill")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(isMatch ? .green : .white.opacity(0.6))
      }
    }
    .frame(width: 36, height: 36)
    .overlay(
        Circle()
            .stroke(isMatch ? Color.green.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
    )
  }

  private var iconText: String? {
    let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
    if !t.isEmpty {
      return String(t.prefix(1)).uppercased()
    }
    let w = website.trimmingCharacters(in: .whitespacesAndNewlines)
    if !w.isEmpty {
      return String(w.prefix(1)).uppercased()
    }
    return nil
  }
}
