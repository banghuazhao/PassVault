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
              performExportShare(format: .json)
            }
            settingsButton(String(localized: "Export vault as CSV"), systemImage: "tablecells") {
              performExportShare(format: .csv)
            }
            settingsButton(String(localized: "Import from JSON or CSV"), systemImage: "square.and.arrow.down") {
              importPickerOpen = true
            }
            settingsButton(
              String(localized: "Delete all passwords"),
              systemImage: "trash",
              role: .destructive,
            ) {
              confirmPurge = true
            }
            
            VStack(alignment: .leading, spacing: 8) {
              Text(String(localized: "Exported JSON contains plaintext passwords. Store exports only somewhere you trust."))
              
              Text(String(localized: "Supported import formats: Bitwarden (JSON), Google Chrome (CSV), Safari (CSV), and Generic (CSV)."))
                .foregroundStyle(VaultGeneratorTheme.accent.opacity(0.8))
              
              Text(String(localized: "Duplicate titles: If an imported item has the same title as an existing one, it will be added with an \"(Imported)\" suffix to ensure no data is lost."))
                .foregroundStyle(Color.white.opacity(0.45))
            }
            .font(.footnote)
            .padding(.top, 8)
          }

          settingsGroup(title: String(localized: "Reminders")) {
            Text(reminderNotificationsSummary)
              .font(.footnote)
              .foregroundStyle(Color.white.opacity(0.68))
              .fixedSize(horizontal: false, vertical: true)

            if notificationAuth == .notDetermined {
              settingsButton(String(localized: "Enable reminder notifications"), systemImage: "bell.badge") {
                Task {
                  let granted = await PasswordReminderScheduler.requestAuthorizationFromSettings()
                  if granted {
                    await home.syncScheduledPasswordReminders()
                  }
                  await refreshNotificationStatus()
                }
              }
            } else if notificationAuth == .denied {
              settingsButton(String(localized: "Open notification settings"), systemImage: "gearshape") {
                if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                  UIApplication.shared.open(url)
                }
              }
              
              Text(
                String(
                  localized:
                    "If notifications were turned off in Settings, use the button above to open PassVault’s notification page.",
                ),
              )
              .font(.footnote)
              .foregroundStyle(Color.white.opacity(0.52))
              .padding(.top, 8)
            } else {
                Text(String(localized: "Reminders are automatically synced with your vault."))
                    .font(.footnote)
                    .foregroundStyle(Color.white.opacity(0.45))
                    .padding(.top, 4)
            }
          }

          settingsGroup(title: String(localized: "Autofill")) {
            VStack(alignment: .leading, spacing: 14) {
              Text(
                String(
                  localized:
                    "The AutoFill extension shares the same protected vault on this device. To enable suggestion in Safari and other apps:"
                )
              )
              .font(.subheadline)
              .foregroundStyle(Color.white.opacity(0.85))
              .fixedSize(horizontal: false, vertical: true)

              NavigationLink {
                AutoFillSetupView()
              } label: {
                HStack(spacing: 12) {
                  Image(systemName: "info.circle.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(VaultGeneratorTheme.accent)
                  Text(String(localized: "View setup instructions"))
                    .font(.body.weight(.medium))
                    .foregroundStyle(Color.white.opacity(0.94))
                  Spacer()
                  Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color.white.opacity(0.28))
                }
                .padding(14)
                .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
              }
              .buttonStyle(.plain)
            }
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
    .fileImporter(isPresented: $importPickerOpen, allowedContentTypes: [.json, .commaSeparatedText]) { result in
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
            let records: [ImportedRecord]
            if url.pathExtension.lowercased() == "csv" {
                records = PassVaultImportExportService.decodeCSV(data: raw)
            } else {
                records = try PassVaultImportExportService.decodeImport(data: raw)
            }
            await home.importRecords(records: records)
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
      return String(localized: "Reminder alerts are on. PassVault will notify you when a password is due for refresh.")
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

  @MainActor
  private func refreshNotificationStatus() async {
    let s = await UNUserNotificationCenter.current().notificationSettings()
    notificationAuth = s.authorizationStatus
    
    // Auto-sync reminders whenever status is checked if authorized
    if notificationAuth == .authorized {
        await home.syncScheduledPasswordReminders()
    }
  }

  private enum ExportFormat {
    case json, csv
  }

  private func performExportShare(format: ExportFormat) {
    do {
      let data: Data
      let filename: String
      
      switch format {
      case .json:
        data = try home.exportArchive()
        filename = "PassVault-export.json"
      case .csv:
        data = try home.exportCSVArchive()
        filename = "PassVault-export.csv"
      }
      
      let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
      try data.write(to: url)
      sharePayload = ExportShareToken(url: url)
    } catch {
      home.lastErrorDescription = error.localizedDescription
    }
  }
}
