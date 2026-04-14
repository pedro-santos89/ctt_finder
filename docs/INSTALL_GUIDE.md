# CTT Finder — Installation Guide

## Prerequisites

| Requirement | Version | Notes |
|-------------|---------|-------|
| **Flutter SDK** | ≥ 3.11.0 | <https://docs.flutter.dev/get-started/install> |
| **Dart SDK** | Bundled with Flutter | — |
| **Git** | Any recent version | For cloning the repo |
| **Internet** | Required at build time | For fetching packages |

### Platform-specific requirements

| Platform | Extra tooling |
|----------|--------------|
| **Windows** | Visual Studio 2022 with the "Desktop development with C++" workload |
| **macOS** | Xcode ≥ 15, CocoaPods (`sudo gem install cocoapods`) |
| **Android** | Android Studio with SDK 21+ (API 21 = Android 5.0) |
| **iOS** | Xcode ≥ 15, a valid Apple Developer account for device builds |
| **Linux** | `clang`, `cmake`, `ninja-build`, `pkg-config`, `libgtk-3-dev` |

---

## 1. Clone the repository

```bash
git clone <repository-url> ctt_finder
cd ctt_finder
```

## 2. Install dependencies

```bash
flutter pub get
```

## 3. Verify your environment

```bash
flutter doctor -v
```

Resolve any issues reported before proceeding.

---

## Running in debug mode

### Windows
```bash
flutter run -d windows
```

### macOS
```bash
flutter run -d macos
```

### Android (emulator or connected device)
```bash
flutter run -d android
```

### iOS (simulator or connected device)
```bash
flutter run -d ios
```

### Web (for quick testing)
```bash
flutter run -d chrome
```

---

## Building release binaries

### Windows (.exe)

```bash
flutter build windows --release
```

Output: `build\windows\x64\runner\Release\`

### macOS (.app)

```bash
flutter build macos --release
```

Output: `build/macos/Build/Products/Release/CTT Finder.app`

### Android (.apk / .aab)

```bash
# APK (for sideloading)
flutter build apk --release

# App Bundle (for Google Play)
flutter build appbundle --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### iOS (.ipa)

```bash
flutter build ipa --release
```

Requires a valid provisioning profile and signing identity.

---

## Creating a Windows installer

An Inno Setup script is provided at `installer/ctt_finder_setup.iss`.

1. Install **Inno Setup 6** from <https://jrsoftware.org/isinfo.php>.
2. Build the Windows release first (`flutter build windows --release`).
3. Open the `.iss` script in Inno Setup Compiler.
4. Press **Compile** (or run from the command line):

```bash
iscc installer\ctt_finder_setup.iss
```

The installer will be created at `installer\Output\CTTFinderSetup.exe`.

---

## Project structure (quick reference)

```
lib/
├── main.dart                  # App entry point & theme
├── models/
│   └── ctt_location.dart      # Data model
├── screens/
│   ├── welcome_screen.dart    # Landing page
│   ├── map_screen.dart        # Map + search + filters
│   └── detail_screen.dart     # Location detail
├── services/
│   ├── app_localizations.dart # i18n (PT / EN)
│   └── ctt_service.dart       # CTT API client
└── widgets/
    ├── filter_sheet.dart      # Filter bottom-sheet
    └── location_card.dart     # Map overlay card
```

---

## Uninstalling

- **Windows installer**: Use *Add or Remove Programs* in Windows Settings.
- **Debug builds**: Simply delete the project folder.

---

*Developed by **Anima Rasa Prod.***
