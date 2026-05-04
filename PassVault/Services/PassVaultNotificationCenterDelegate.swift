//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import UserNotifications

final class PassVaultNotificationCenterDelegate: NSObject, UNUserNotificationCenterDelegate {
  static let shared = PassVaultNotificationCenterDelegate()

  func userNotificationCenter(
    _: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completion: @escaping (UNNotificationPresentationOptions) -> Void,
  ) {
    completion([.banner, .sound, .list])
  }

  func userNotificationCenter(
    _: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completion: @escaping () -> Void,
  ) {
    completion()
  }
}
