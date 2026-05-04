//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI
import UIKit

/// Grid of emoji glyphs for password list icons (stored as UTF-8 in the same field as legacy SF Symbol names).
struct VaultEmojiPickerSheet: View {
  @Binding var selection: String
  @Environment(\.dismiss) private var dismiss
  @State private var query = ""

  /// Curated common credential / life-context emoji; `hints` powers search.
  private static let choices: [(emoji: String, hints: String)] = [
    ("🔐", "lock vault security"),
    ("🔑", "key password login"),
    ("🗝️", "key old lock"),
    ("🔒", "locked"),
    ("🔓", "unlocked open"),
    ("🌐", "web internet globe site"),
    ("💻", "computer laptop work"),
    ("📱", "phone mobile iphone"),
    ("⌚", "watch wearable"),
    ("📧", "email mail inbox"),
    ("✉️", "letter envelope message"),
    ("💳", "card credit banking pay"),
    ("🏦", "bank finance atm"),
    ("💰", "money cash dollar savings"),
    ("🏠", "home house personal"),
    ("🏢", "office building work company"),
    ("🛒", "cart shopping store retail"),
    ("✈️", "plane travel flight airline"),
    ("🚗", "car auto vehicle"),
    ("🚲", "bike bicycle"),
    ("🏥", "hospital medical health"),
    ("💊", "pill medicine pharmacy"),
    ("🎮", "game gaming play"),
    ("🎬", "movie film streaming"),
    ("🎵", "music audio sound"),
    ("📚", "book study school"),
    ("🎓", "graduation university education"),
    ("📷", "camera photo"),
    ("🎨", "art design creative"),
    ("⚽", "sport fitness"),
    ("🏆", "trophy reward achievement"),
    ("❤️", "heart favorite love"),
    ("⭐", "star favorite important"),
    ("☁️", "cloud drive storage"),
    ("📎", "clip attach document"),
    ("📁", "folder files"),
    ("📝", "note memo text"),
    ("🔔", "bell notification alert"),
    ("🌍", "world international"),
    ("👤", "person user profile"),
    ("🆔", "id identity"),
    ("🐕", "pet dog"),
    ("🐈", "cat pet"),
    ("☕", "coffee cafe food"),
    ("🍕", "pizza food delivery"),
    ("🏋️", "gym fitness"),
    ("🎯", "target focus"),
    ("🧩", "puzzle extension plugin"),
    ("⚡", "bolt fast power"),
    ("🔥", "fire hot trending"),
    ("💡", "idea lamp light"),
    ("🛡️", "shield protect safety"),
    ("📍", "pin location map"),
  ]

  private var filtered: [(emoji: String, hints: String)] {
    let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard !q.isEmpty else { return Self.choices }
    return Self.choices.filter { pair in
      pair.hints.lowercased().contains(q) || pair.emoji.contains(q)
    }
  }

  private let columns = [GridItem(.adaptive(minimum: 64), spacing: 12)]

  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVGrid(columns: columns, spacing: 16) {
          ForEach(filtered, id: \.emoji) { pair in
            Button {
              selection = pair.emoji
              dismiss()
            } label: {
              Text(pair.emoji)
                .font(.system(size: 36))
                .frame(width: 60, height: 60)
                .background(Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(pair.hints))
          }
        }
        .padding(16)
      }
      .background(Color(.systemGroupedBackground))
      .navigationTitle(String(localized: "Choose emoji"))
      .navigationBarTitleDisplayMode(.inline)
      .searchable(text: $query, prompt: String(localized: "Search"))
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button(String(localized: "Cancel")) {
            dismiss()
          }
        }
      }
    }
  }
}
