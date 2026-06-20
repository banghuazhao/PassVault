# PassVault

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)](https://github.com/banghuazhao/PassVault)
[![Platform](https://img.shields.io/badge/platform-iOS-blue)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange)](https://swift.org)
[![App Store](https://img.shields.io/badge/App%20Store-Download-0D96F6?logo=appstore&logoColor=white)](https://apps.apple.com/nz/app/passvault-secure-pass-manager/id6780150333)

PassVault is a secure, elegant, and industry-standard iOS password manager, now available on the App Store. Designed with a premium "glassy" dark theme, it offers a seamless experience for managing credentials on your device with a powerful Autofill extension and robust data portability.

## 📲 Download

PassVault is available for iPhone on the App Store:

[Download PassVault: Secure Pass Manager](https://apps.apple.com/nz/app/passvault-secure-pass-manager/id6780150333)

## ✨ Features

### 🔐 Premium Security & UI
- **Modern Dark Theme**: A beautiful, "glassy" user interface designed for focus and clarity.
- **Biometric Ready**: Built with security at its core, ready for FaceID/TouchID integration.
- **Haptic Feedback**: High-quality sensory feedback for a tactile, premium experience.

### 🧩 Advanced Autofill Extension
- **Smart Suggestions**: Automatically suggests credentials based on the current website or app.
- **In-Extension Creation**: Save new logins directly from the Autofill interface without switching apps.
- **Password Generator**: Integrated secure generator available everywhere you need it.

### 📂 Organization & Management
- **Categorization**: Group credentials into custom folders with unique icons.
- **Batch Operations**: Easily migrate or delete entire categories of passwords.
- **Smart Search**: Quickly find what you need with real-time search across titles and domains.
- **Rotation Reminders**: Automated notifications to remind you when it's time to refresh critical passwords.

### 🔄 Data Portability (Industry Standard)
- **Universal Import**: Migrate seamlessly from **Google Chrome**, **Safari**, **Bitwarden**, **1Password**, and **LastPass**.
- **Supported Formats**: Full support for `.json` (Bitwarden compatible) and `.csv` (Generic/Manager exports).
- **Smart Merge**: Collision protection for duplicate titles—no data is ever overwritten during import.
- **Flexible Export**: Back up your vault as Bitwarden-compatible JSON or standard CSV.

## 🛠 Technical Stack

- **Swift 6**: Utilizing the latest Swift concurrency features and safety standards.
- **SwiftUI**: A modern, declarative UI framework for a responsive experience.
- **GRDB**: Robust, high-performance SQLite access with advanced data protection.
- **CryptoKit**: Industry-standard AES-GCM encryption for securing your vault.
- **Observation Framework**: Modern state management for efficient UI updates.

## 🚀 Development Setup

### Prerequisites
- Xcode 16.0 or later
- iOS 18.0 or later

### Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/banghuazhao/PassVault.git
   ```
2. Open `PassVault.xcodeproj` in Xcode.
3. Configure your **App Group** (`group.com.appsbay.PassVault`) in the project's Signing & Capabilities tab for both the main app and the Autofill extension.
4. Build and run on your physical device or simulator.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request or open an issue.

## 📄 License

Copyright © 2026 Apps Bay Limited. All rights reserved.

---

Built with ❤️ by [Banghua Zhao](https://github.com/banghuazhao)
