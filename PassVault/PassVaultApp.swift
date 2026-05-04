//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SQLiteData
import SwiftUI
import UserNotifications

@main
struct PassVaultApp: App {
  init() {
    UNUserNotificationCenter.current().delegate = PassVaultNotificationCenterDelegate.shared
    do {
      let queue = try AppDatabase.makeDatabaseQueue()
      prepareDependencies {
        $0.defaultDatabase = queue
      }
    } catch {
      fatalError("PassVault could not bootstrap SQLite: \(error)")
    }
  }

  var body: some Scene {
    WindowGroup {
      MainTabView()
        .preferredColorScheme(.dark)
    }
  }
}
