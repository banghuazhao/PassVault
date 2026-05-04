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
    let settings = await center.notificationSettings()
    guard settings.authorizationStatus == .notDetermined else { return }
    _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
  }

  /// Re-sync pending requests with the vault (e.g. after launch or permission grant).
  @MainActor
  static func rescheduleAll(rows: [VaultPasswordRow]) async {
    for row in rows {
      await reschedule(row: row)
    }
  }

  /// Requests permission when `.notDetermined`; returns whether reminders may be scheduled.
  @MainActor
  static func requestAuthorizationFromSettings() async -> Bool {
    let center = UNUserNotificationCenter.current()
    let before = await center.notificationSettings().authorizationStatus
    if before == .notDetermined {
      guard let granted = try? await center.requestAuthorization(options: [.alert, .sound, .badge]) else {
        return false
      }
      return granted
    }
    return before == .authorized || before == .ephemeral || before == .provisional
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
    let displayTitle = row.title.trimmingCharacters(in: .whitespacesAndNewlines)
    if displayTitle.isEmpty {
      content.title = String(localized: "Password rotation due")
    }
    else {
      content.title = String(
        format: String(localized: "Password update — %@"),
        displayTitle,
      )
    }
    content.body =
      String(
        localized: "Rotate this passphrase on schedule to keep your vault in good standing.",
      )
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
