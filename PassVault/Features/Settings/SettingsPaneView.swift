//
// Created by Banghua Zhao on 04/05/2026
// Copyright Apps Bay Limited. All rights reserved.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers
import UserNotifications

private struct ExportShareToken: Identifiable {
  let id = UUID()
  let url: URL
}

struct SettingsPaneView: View {
  @Bindable var home: HomeViewModel

  @AppStorage("passvault.autofill.guidanceSeen") private var autofillAck = false

  @State private var confirmPurge = false
  @State private var importPickerOpen = false
  @State private var sharePayload: ExportShareToken?
  @State private var notificationAuth: UNAuthorizationStatus = .notDetermined

  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 18) {
          settingsGroup(title: String(localized: "Data")) {
            settingsButton(String(localized: "Export vault as JSON"), systemImage: "square.and.arrow.up") {
              performExportShare()
            }
            settingsButton(String(localized: "Import vault from JSON"), systemImage: "square.and.arrow.down") {
              importPickerOpen = true
            }
            settingsButton(
              String(localized: "Delete all passwords"),
              systemImage: "trash",
              role: .destructive,
            ) {
              confirmPurge = true
            }
            Text(String(localized: "Exported JSON contains plaintext passwords. Store exports only somewhere you trust."))
              .font(.footnote)
              .foregroundStyle(Color.white.opacity(0.55))
              .padding(.top, 4)
          }

          settingsGroup(title: String(localized: "Reminders")) {
            Text(reminderNotificationsSummary)
              .font(.footnote)
              .foregroundStyle(Color.white.opacity(0.68))
              .fixedSize(horizontal: false, vertical: true)

            settingsButton(notificationPrimaryTitle, systemImage: notificationPrimaryIcon) {
              Task {
                await runNotificationPrimaryAction()
                await refreshNotificationStatus()
              }
            }

            if notificationAuth == .denied {
              Text(
                String(
                  localized:
                    "If notifications were turned off in Settings, use the button above to open PassVault’s notification page.",
                ),
              )
              .font(.footnote)
              .foregroundStyle(Color.white.opacity(0.52))
            }
          }

          settingsGroup(title: String(localized: "Autofill")) {
            Toggle(isOn: $autofillAck) {
              Label(String(localized: "Show AutoFill note"), systemImage: "text.badge.checkmark")
            }
            .tint(VaultGeneratorTheme.accent)
            Text(
              String(
                localized:
                  "True iOS Password AutoFill needs an associated Credential Provider extension in this Xcode project.",
              )
            )
            .font(.footnote)
            .foregroundStyle(Color.white.opacity(0.55))
          }

          settingsGroup(title: String(localized: "Privacy")) {
            Text(
              String(
                localized:
                  "PassVault keeps everything on-device. Clearing this app deletes the vault permanently unless you exported a backup.",
              )
            )
            .font(.footnote)
            .foregroundStyle(Color.white.opacity(0.68))
          }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
      }
      .vaultBackdrop()
      .navigationTitle(String(localized: "Settings"))
    }
    .preferredColorScheme(.dark)
    .task {
      await refreshNotificationStatus()
    }
    .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
      Task { await refreshNotificationStatus() }
    }
    .fileImporter(isPresented: $importPickerOpen, allowedContentTypes: [.json]) { result in
      switch result {
      case let .success(url):
        Task {
          let needsAccess = url.startAccessingSecurityScopedResource()
          defer {
            if needsAccess {
              url.stopAccessingSecurityScopedResource()
            }
          }
          guard let raw = try? Data(contentsOf: url) else { return }
          do {
            let envelope = try PassVaultImportExportService.decodeImport(data: raw)
            await home.importRecords(
              records: envelope.records,
              defaultCategoryId: home.categories.first?.id,
            )
          } catch {
            home.lastErrorDescription = error.localizedDescription
          }
        }

      case .failure:
        break
      }
    }
    .sheet(item: $sharePayload) { token in
      IosActivityBridge(activityItems: [token.url])
    }
    .alert(
      String(localized: "Erase entire vault"),
      isPresented: $confirmPurge,
      actions: {
        Button(String(localized: "Cancel"), role: .cancel, action: {})
        Button(String(localized: "Erase all"), role: .destructive) {
          Task {
            await home.deleteAllPasswords()
          }
        }
      },
      message: {
        Text(String(localized: "This removes every password and cancels reminders. Categories stay."))
      },
    )
    .alert(
      String(localized: "Notice"),
      isPresented: Binding(
        get: { home.lastErrorDescription != nil },
        set: { flag in if !flag { home.clearError() } },
      ),
      actions: {
        Button(String(localized: "Dismiss"), role: .cancel) {
          home.clearError()
        }
      },
      message: {
        Text(home.lastErrorDescription ?? "")
      },
    )
  }

  private func settingsGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(title.uppercased())
        .font(.footnote.weight(.semibold))
        .foregroundStyle(Color.white.opacity(0.48))
      VStack(alignment: .leading, spacing: 0) {
        content()
      }
      .padding(14)
      .frame(maxWidth: .infinity, alignment: .leading)
      .vaultCard()
    }
  }

  private func settingsButton(_ title: String, systemImage: String, role: ButtonRole? = nil, action: @escaping () -> Void)
    -> some View
  {
    Button(role: role, action: action) {
      HStack(spacing: 12) {
        Image(systemName: systemImage)
          .font(.body.weight(.semibold))
          .foregroundStyle(role == .destructive ? Color.red.opacity(0.9) : Color.white.opacity(0.92))
          .frame(width: 28)
        Text(title)
          .foregroundStyle(role == .destructive ? Color.red.opacity(0.95) : Color.white.opacity(0.94))
        Spacer()
        Image(systemName: "chevron.right")
          .font(.caption.weight(.bold))
          .foregroundStyle(Color.white.opacity(0.28))
      }
      .padding(.vertical, 10)
    }
    .buttonStyle(.plain)
  }

  private var reminderNotificationsSummary: String {
    switch notificationAuth {
    case .authorized:
      return String(localized: "Reminder alerts are on. Tap below to re-sync scheduled dates with your vault.")
    case .denied:
      return String(
        localized:
          "PassVault can’t show rotation reminders until notifications are allowed in System Settings.",
      )
    case .ephemeral, .provisional:
      return String(localized: "Reminder delivery is limited or provisional on this device.")
    case .notDetermined:
      return String(
        localized:
          "Allow notifications so PassVault can alert you on the device when a password is due for refresh.",
      )
    @unknown default:
      return ""
    }
  }

  private var notificationPrimaryTitle: String {
    switch notificationAuth {
    case .notDetermined:
      return String(localized: "Enable reminder notifications")
    case .denied:
      return String(localized: "Open notification settings")
    case .authorized, .ephemeral, .provisional:
      return String(localized: "Refresh reminder schedule")
    @unknown default:
      return String(localized: "Notifications")
    }
  }

  private var notificationPrimaryIcon: String {
    switch notificationAuth {
    case .denied:
      return "gearshape"
    default:
      return "bell.badge"
    }
  }

  @MainActor
  private func runNotificationPrimaryAction() async {
    switch notificationAuth {
    case .notDetermined:
      let granted = await PasswordReminderScheduler.requestAuthorizationFromSettings()
      if granted {
        await home.syncScheduledPasswordReminders()
      }
    case .denied:
      if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
        await UIApplication.shared.open(url)
      }
    case .authorized, .ephemeral, .provisional:
      await home.syncScheduledPasswordReminders()
    @unknown default:
      break
    }
  }

  @MainActor
  private func refreshNotificationStatus() async {
    let s = await UNUserNotificationCenter.current().notificationSettings()
    notificationAuth = s.authorizationStatus
  }

  private func performExportShare() {
    do {
      let data = try home.exportArchive()
      let url =
        FileManager.default.temporaryDirectory.appendingPathComponent("PassVault-export.json")
      try data.write(to: url)
      sharePayload = ExportShareToken(url: url)
    } catch {
      home.lastErrorDescription = error.localizedDescription
    }
  }
}
