//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import UserNotifications

nonisolated enum PasswordReminderScheduler {
  static func notificationIdentifier(forEntryId id: Int) -> String {
    "password-rotation-\(id)"
  }

  @MainActor
  static func requestAuthorizationIfNeeded() async {
    let center = UNUserNotificationCenter.current()
    _ = try? await center.requestAuthorization(options: [.alert, .sound])
  }

  @MainActor
  static func reschedule(row: VaultPasswordRow) async {
    let id = Self.notificationIdentifier(forEntryId: row.id)
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])

    guard let interval = row.reminderIntervalMonths,
      interval > 0,
      let due = row.reminderNextDue,
      due > Date()
    else {
      return
    }

    let content = UNMutableNotificationContent()
    content.title = "Update “\(row.title)”"
    content.body = "It is time to rotate this password and keep your vault healthy."
    content.sound = .default

    let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: due)
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

    let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
    try? await UNUserNotificationCenter.current().add(request)
  }

  @MainActor
  static func cancel(entryId: Int) {
    let id = Self.notificationIdentifier(forEntryId: entryId)
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
  }
}
