//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import GoogleMobileAds
import SQLiteData
import SwiftUI
import UserNotifications

@main
struct PassVaultApp: App {
    @State private var appOpenAdManager = AppOpenAdManager()

    init() {
        UNUserNotificationCenter.current().delegate = PassVaultNotificationCenterDelegate.shared
        do {
            let queue = try AppDatabase.makeDatabaseQueue()
            prepareDependencies {
                $0.defaultDatabase = queue
            }
        } catch {
            fatalError("PassVault could not bootstrap SQLite: \(error.localizedDescription)")
        }
        GADMobileAds.sharedInstance().start(completionHandler: nil)
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .preferredColorScheme(.dark)
                .onReceive(
                    NotificationCenter.default.publisher(
                        for: UIApplication.willEnterForegroundNotification
                    )
                ) { _ in
                    appOpenAdManager.showAdIfAvailable()
                }
        }
    }
}
