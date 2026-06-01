//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import Charts
import SwiftUI

struct AnalyzePaneView: View {

  let analyze: AnalyzeViewModel

  init(analyze: AnalyzeViewModel) {
    self.analyze = analyze
  }

  var body: some View {
    NavigationStack {
      Group {
        if analyze.passwords.isEmpty {
          ContentUnavailableView {
            Label(String(localized: "Insights unavailable"), systemImage: "chart.bar.xaxis")
              .foregroundStyle(.white)
          } description: {
            Text(String(localized: "Create your first credential to start analyzing your vault's security and usage."))
              .foregroundStyle(.white.opacity(0.6))
          }
        } else {
          ScrollView {
            LazyVStack(alignment: .leading, spacing: 22) {
              SectionCap(String(localized: "Overview"))
              overviewGrid.vaultCard()

              SectionCap(String(localized: "Strength distribution"))
              strengthChart.vaultCard()

              SectionCap(String(localized: "Tap cadence (~12 weeks)"))
              tapsChart.vaultCard()

              SectionCap(String(localized: "Reminder calendar"))
              RotationPlanner(analyze: analyze).vaultCard()

              SectionCap(String(localized: "Fingerprint duplication"))
              reuseCard.vaultCard()

              SectionCap(String(localized: "Insights"))
              coachCard.vaultCard()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
          }
        }
      }
      .vaultBackdrop()
      .navigationTitle(String(localized: "Analyze"))
    }
    .preferredColorScheme(.dark)
  }

  private var overviewGrid: some View {
    LazyVGrid(columns: [.init(.flexible()), .init(.flexible()), .init(.flexible())], spacing: 12) {
      StatCell(title: String(localized: "Entries"), value: analyze.passwords.count, tint: Color.accentColor)
      StatCell(title: String(localized: "Weak"), value: analyze.weakCounts, tint: Color.orange)
      StatCell(title: String(localized: "Reuse clusters"), value: analyze.reuseGroups().count, tint: Color.red)
    }
  }

  private var strengthChart: some View {
    Chart {
      BarMark(x: .value("Tier", PasswordStrengthLevel.strong.displayTitle), y: .value("Qty", analyze.strongCounts))
        .foregroundStyle(Color.green.opacity(0.75))
      BarMark(x: .value("Tier", PasswordStrengthLevel.medium.displayTitle), y: .value("Qty", analyze.mediumCounts))
        .foregroundStyle(Color.yellow.opacity(0.72))
      BarMark(x: .value("Tier", PasswordStrengthLevel.weak.displayTitle), y: .value("Qty", analyze.weakCounts))
        .foregroundStyle(Color.orange.opacity(0.78))
    }
    .chartXAxis(.automatic)
    .chartYAxis(.automatic)
    .frame(height: 220)
    .foregroundStyle(Color.white.opacity(0.95))
    .padding(.horizontal, 4)
  }

  private var tapsChart: some View {

    let buckets = analyze.weeklyTapSeries()

    return Group {

      if buckets.isEmpty {

        BlurbHint(String(localized: "Open entries and copy secrets so weekly taps appear on this curve."))

      }

      Chart {
        ForEach(Array(buckets.enumerated()), id: \.offset) { _, bucket in
          AreaMark(x: .value("Week start", bucket.weekStart, unit: .weekOfYear), y: .value("Taps", bucket.taps))
            .foregroundStyle(Color.accentColor.opacity(0.14))

          LineMark(x: .value("Week start", bucket.weekStart, unit: .weekOfYear), y: .value("Taps", bucket.taps))
            .interpolationMethod(.catmullRom)
            .foregroundStyle(Color.accentColor.gradient)
        }
      }
      .chartXAxis(.automatic)
      .chartYAxis(.automatic)
      .frame(height: buckets.isEmpty ? 0 : 220)
      .foregroundStyle(Color.white.opacity(0.95))
      .opacity(buckets.isEmpty ? 0 : 1)
      .accessibilityHidden(buckets.isEmpty)
      .animation(.easeInOut(duration: 0.2), value: buckets.count)
    }
  }

  private var reuseCard: some View {
    VStack(alignment: .leading, spacing: 14) {
      if let digest = analyze.topReusedFingerprint() {
        BlurbBold(
          title: String(localized: "Highest reuse digest"),
          subtitle: "Reuse fingerprint — \(digest.prefix(18))…",
        )
      }
      else {
        BlurbHint(String(localized: "No hashed duplicates surfaced across stored fingerprints."))
      }

      Divider().opacity(0.3)

      ForEach(analyze.fingerprintReuseStats(), id: \.fingerprint) { stat in
        HStack {
          Image(systemName: "link.circle")
          Text("\(stat.fingerprint.prefix(28))…").font(.caption.monospaced())
          Spacer(minLength: 8)
          Text("×\(stat.count)")
            .foregroundStyle(Color.white.opacity(0.7))
        }
        .foregroundStyle(Color.white.opacity(0.9))
      }
    }
    .foregroundStyle(Color.white.opacity(0.92))
    .fixedSize(horizontal: false, vertical: true)
  }

  private var coachCard: some View {
    VStack(alignment: .leading, spacing: 12) {
      ForEach(Array(analyze.suggestions().enumerated()), id: \.offset) { _, tip in
        Label {
          Text(tip)
        } icon: {
          Image(systemName: "sparkles")
            .foregroundStyle(Color.yellow.opacity(0.9))
        }
        .foregroundStyle(Color.white.opacity(0.92))
        .fixedSize(horizontal: false, vertical: true)
      }
    }
  }
}

// MARK: - Calendar

private struct RotationPlanner: View {

  let analyze: AnalyzeViewModel

  private let calendar = Calendar.current

  private var anchor: Date {
    switch analyze.calendarFocus {
    case let .month(year, month):
      return calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
    }
  }

  private var bucketPerDayStart: [Date: Int] { analyze.rotationCalendarDays() }

  private var leadingPads: Int {
    let weekday = calendar.component(.weekday, from: anchor)
    let first = calendar.firstWeekday
    return (weekday - first + 7) % 7
  }

  private var dayNumbers: [Int] {
    guard let rng = calendar.range(of: .day, in: .month, for: anchor) else { return [] }
    return Array(rng)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      header
      weekdaysRow

      LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
        ForEach(0..<leadingPads, id: \.self) { _ in
          Color.clear.frame(height: 36)
        }
        ForEach(dayNumbers, id: \.self) { dayNum in
          dayCell(day: dayNum)
        }
      }

      BlurbHint(String(localized: "Highlighted days host one or more scheduled password refresh prompts."))
    }
  }

  private var header: some View {
    HStack {
      Button {
        analyze.shiftFocusedMonth(by: -1)
      } label: {
        Image(systemName: "chevron.left.circle.fill")
      }
      .accessibilityLabel(String(localized: "Previous month"))

      Spacer()

      Text(anchor, format: .dateTime.month(.wide).year())
        .font(.headline.weight(.semibold))

      Spacer()

      Button {
        analyze.shiftFocusedMonth(by: 1)
      } label: {
        Image(systemName: "chevron.right.circle.fill")
      }
      .accessibilityLabel(String(localized: "Next month"))
    }
  }

  private var weekdaysRow: some View {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 4) {
      ForEach(Array(weekdayColumnLabels.enumerated()), id: \.offset) { _, symbol in
        Text(symbol.uppercased())
          .font(.caption2.bold())
          .foregroundStyle(Color.white.opacity(0.55))
          .frame(maxWidth: .infinity)
      }
    }
  }

  /// Column 0 aligns with `Calendar.firstWeekday` (fixes misaligned grids for Monday-first locales — e.g. Aug 2026).
  private var weekdayColumnLabels: [String] {
    let syms = calendar.shortWeekdaySymbols
    guard syms.count >= 7 else {
      return calendar.shortStandaloneWeekdaySymbols.map { $0.uppercased(with: .current) }
    }
    return (0..<7).map { column in
      let weekdayNum = ((calendar.firstWeekday - 1 + column) % 7) + 1  // weekday 1 = Sunday
      return syms[weekdayNum - 1]
    }
  }

  private func dayCell(day: Int) -> some View {
    let year = calendar.component(.year, from: anchor)
    let month = calendar.component(.month, from: anchor)
    let stamp = calendar.date(from: DateComponents(year: year, month: month, day: day)) ?? anchor
    let key = calendar.startOfDay(for: stamp)
    let count = bucketPerDayStart[key, default: 0]

    return ZStack {
      Circle()
        .fill(count > 0 ? Color.accentColor.opacity(0.32) : Color.white.opacity(0.06))
      Text("\(day)")
        .font(.callout.weight(.bold))
        .foregroundStyle(Color.white.opacity(0.93))
    }
    .frame(width: 36, height: 36)
    .accessibilityLabel(String(localized: "Day \(day) — reminders \(count)"))
  }
}

// MARK: - Small primitives

private struct SectionCap: View {

  let title: String

  init(_ title: String) {
    self.title = title
  }

  var body: some View {
    Text(title)
      .font(.footnote.weight(.semibold))
      .foregroundStyle(Color.white.opacity(0.56))
      .textCase(.uppercase)
  }
}

private struct BlurbHint: View {

  let message: String

  init(_ message: String) {
    self.message = message
  }

  var body: some View {
    Text(message)
      .foregroundStyle(Color.white.opacity(0.68))
      .font(.callout)
      .fixedSize(horizontal: false, vertical: true)
  }
}
private struct BlurbBold: View {
  let title: String
  let subtitle: String

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .font(.headline.weight(.semibold))

      Text(subtitle)
        .font(.footnote)
        .foregroundStyle(Color.white.opacity(0.7))
    }
  }
}

private struct StatCell: View {
  let title: String
  let value: Int
  let tint: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("\(value)")
        .font(.title.bold())
        .monospacedDigit()
        .foregroundStyle(Color.white)

      Text(title)
        .font(.caption.weight(.semibold))
        .foregroundStyle(Color.white.opacity(0.62))

      Spacer(minLength: 0)
    }
    .padding(12)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(tint.opacity(0.09), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
  }
}

