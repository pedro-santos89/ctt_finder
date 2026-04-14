# CTT Finder

A cross-platform Flutter application for locating Portuguese postal service (CTT) stores, access points and mailboxes across Portugal.

![Flutter](https://img.shields.io/badge/Flutter-%5E3.11.0-02569B?logo=flutter)
![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS%20%7C%20Windows%20%7C%20macOS%20%7C%20Web-brightgreen)
![License](https://img.shields.io/badge/License-Proprietary-red)

## Features

- **Interactive map** — OpenStreetMap-based map with clustered markers for stations (red) and mailboxes (orange)
- **CTT API search** — queries the official CTT station-search endpoint for real-time results
- **Cascading geographic filters** — district → municipality → parish dropdowns
- **GPS location** — shows your position as a blue dot and provides directions from your current location
- **Bilingual UI** — full Portuguese and English support, switchable at any time
- **Detail view** — address, schedule, phone, services, coordinates, Google Maps directions, share
- **List view** — scrollable bottom-sheet listing all loaded results
- **Custom branding** — CTT corporate fonts (ActoCTT-Bold, ActoCTT-Medium) and colour scheme (#DF0024)

## Screenshots

| Welcome | Map | Detail |
|---------|-----|--------|
| Red gradient with CTT Finder branding | Interactive map with markers and search bar | Full location info with services and actions |

## Getting Started

### Prerequisites

| Requirement | Version |
|-------------|---------|
| Flutter SDK | ≥ 3.11.0 |
| Dart SDK | Bundled with Flutter |

Platform-specific tooling (Visual Studio for Windows, Xcode for macOS/iOS, Android Studio for Android). See [docs/INSTALL_GUIDE.md](docs/INSTALL_GUIDE.md) for full details.

### Install & Run

```bash
git clone https://github.com/pedro-santos89/ctt_finder.git
cd ctt_finder
flutter pub get
flutter run -d windows   # or: android, ios, macos, chrome
```

### Build Release

```bash
flutter build windows --release   # Output: build/windows/x64/runner/Release/
flutter build apk --release       # Output: build/app/outputs/flutter-apk/
flutter build macos --release     # Output: build/macos/Build/Products/Release/
```

### Windows Installer

A pre-built installer is available on the [Releases](https://github.com/pedro-santos89/ctt_finder/releases) page.

To build it yourself:

```bash
flutter build windows --release
iscc installer\ctt_finder_setup.iss
```

Requires [Inno Setup 6](https://jrsoftware.org/isinfo.php).

## Project Structure

```
lib/
├── main.dart                  # App entry point & theme
├── models/
│   └── ctt_location.dart      # Data model (CttLocation, enums)
├── screens/
│   ├── welcome_screen.dart    # Landing page with branding
│   ├── map_screen.dart        # Main map + search + filters
│   └── detail_screen.dart     # Location detail view
├── services/
│   ├── app_localizations.dart # Bilingual strings (PT / EN)
│   └── ctt_service.dart       # CTT API client & HTML parser
└── widgets/
    ├── filter_sheet.dart      # Filter bottom-sheet
    └── location_card.dart     # Map overlay card
```

## Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_map` | Interactive map widget |
| `latlong2` | Geographic coordinate types |
| `geolocator` | GPS location access |
| `http` | HTTP requests to CTT API |
| `html` | HTML parsing of search results |
| `url_launcher` | External links (directions, phone, website) |
| `flutter_map_marker_cluster` | Marker clustering on the map |
| `cached_network_image` | Image caching |

## Documentation

- [Usage Manual](docs/USAGE_MANUAL.md) — how to use the app
- [Install Guide](docs/INSTALL_GUIDE.md) — build & install instructions for all platforms

## App Icon

Generated with `python scripts/generate_icon.py` using the app's brand colours and ActoCTT fonts. Platform icons are applied via `flutter_launcher_icons`.

---

*Developed by **Anima Rasa Prod. 2026***
