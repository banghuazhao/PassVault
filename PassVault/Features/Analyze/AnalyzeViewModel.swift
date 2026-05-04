//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Foundation
import Observation
import SQLiteData

@Observable
@MainActor
final class AnalyzeViewModel {

  enum CalendarFocus: Identifiable {
    case month(year: Int, month: Int)

    var id: String {
      switch self {
      case let .month(year: y, month: m):
        "m-\(y)-\(m)"
      }
    }

    static func currentMonth() -> CalendarFocus {
      let components = Calendar.current.dateComponents([.year, .month], from: Date())
      return .month(year: components.year ?? 0, month: components.month ?? 1)
    }
  }

  @ObservationIgnored @FetchAll(VaultPasswordRow.all) private var fetchedPasswords: [VaultPasswordRow]

  var passwords: [VaultPasswordRow] { fetchedPasswords }
  var calendarFocus: CalendarFocus = .currentMonth()

  init() {}

  func shiftFocusedMonth(by delta: Int) {
    let calendar = Calendar.current
    switch calendarFocus {
    case let .month(year, month):
      guard let anchor = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
        let shifted = calendar.date(byAdding: .month, value: delta, to: anchor)
      else {
        return
      }
      let comps = calendar.dateComponents([.year, .month], from: shifted)
      guard let yy = comps.year, let mm = comps.month else { return }
      calendarFocus = .month(year: yy, month: mm)
    }
  }

  var weakCounts: Int {
    var total = 0
    for row in passwords {
      if let plaintext = try? VaultSecrets.plaintext(from: row),
        PasswordStrengthEvaluator.evaluate(password: plaintext) == .weak
      {
        total += 1
      }
    }
    return total
  }

  var mediumCounts: Int {
    var total = 0
    for row in passwords {
      if let plaintext = try? VaultSecrets.plaintext(from: row),
        PasswordStrengthEvaluator.evaluate(password: plaintext) == .medium
      {
        total += 1
      }
    }
    return total
  }

  var strongCounts: Int {
    var total = 0
    for row in passwords {
      if let plaintext = try? VaultSecrets.plaintext(from: row),
        PasswordStrengthEvaluator.evaluate(password: plaintext) == .strong
      {
        total += 1
      }
    }
    return total
  }

  func reuseGroups() -> [[VaultPasswordRow]] {
    Dictionary(grouping: passwords, by: \.reuseFingerprint)
      .filter { $0.key != "" && ($0.value.count > 1) }
      .map(\.value)
  }

  func fingerprintReuseStats() -> [(fingerprint: String, count: Int)] {
    duplicateFingerprintsSorted()
  }

  func topReusedFingerprint() -> String? {
    duplicateFingerprintsSorted().first?.fingerprint
  }

  /// Weekly tap aggregates for Swift Charts (`weekStart` ascending).
  func weeklyTapSeries() -> [(weekStart: Date, taps: Int)] {
    var buckets: [Date: Int] = [:]
    let calendar = Calendar.current
    guard let horizon = calendar.date(byAdding: .weekOfYear, value: -11, to: Date()) else {
      return []
    }
    let normalizedHorizon =
      calendar.startOfDay(for: horizon)

    for row in passwords {
      let opened = row.lastOpenedAt ?? row.updatedAt
      guard opened >= normalizedHorizon else { continue }

      guard let interval = calendar.dateInterval(of: .weekOfYear, for: opened) else { continue }
      let week = interval.start
      buckets[week, default: 0] += max(row.tapCount, 1)
    }

    return buckets
      .map { (weekStart: $0.key, taps: $0.value) }
      .sorted(by: { $0.weekStart < $1.weekStart })
  }

  func rotationCalendarDays() -> [Date: Int] {
    var map: [Date: Int] = [:]
    let calendar = Calendar.current

    switch calendarFocus {
    case let .month(year, month):
      for row in passwords {
        guard let due = row.reminderNextDue else { continue }
        let compsDue = calendar.dateComponents([.year, .month], from: due)
        guard compsDue.year == year, compsDue.month == month else { continue }
        let day = calendar.startOfDay(for: due)
        map[day, default: 0] += 1
      }
    }
    return map
  }

  func suggestions() -> [String] {
    var tips: [String] = []

    let weakPw = weakCounts
    let reuse = reuseGroups()

    if weakPw > 0 {
      tips.append("You currently keep \(weakPw) weak passphrase(s). Updating them materially improves resilience.")
    }
    if reuse.count > 0 {
      tips.append("Reuse detected across \(reuse.count) cluster(s)—unique secrets per login stop lateral movement.")
    }
    if passwords.allSatisfy({ $0.reminderIntervalMonths == nil }) {
      tips.append(
        "Add rotation reminders to high-value credentials so upkeep stays deliberate instead of improvised.",
      )
    }
    let missingWebsite =
      passwords
      .filter { row in
        row.website.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      }
      .count
    if missingWebsite > 3 {
      tips.append("Annotate URLs for logins—they improve icon matching and auditing later.")
    }
    if tips.isEmpty {
      tips.append("Healthy vault fundamentals look solid—keep periodic reviews on your cadence.")
    }
    return tips
  }

  private func duplicateFingerprintsSorted() -> [(fingerprint: String, count: Int)] {
    passwords
      .filter { !$0.reuseFingerprint.isEmpty }
      .reduce(into: [String: Int]()) { counts, row in
        counts[row.reuseFingerprint, default: 0] += 1
      }
      .filter { $0.value > 1 }
      .map { (fingerprint: $0.key, count: $0.value) }
      .sorted(by: { $0.count > $1.count })
  }
}
