# Diyaa

A Flutter Islamic companion app that helps Muslims maintain their daily worship through azkar reminders, prayer time tracking, progress achievements, and a rewards shop.

## Features

- **Azkar (Remembrances)** — Daily azkar sessions with a browsable library of adhkar from authentic sources
- **Prayer Times** — Automatic location-based prayer time calculations with local notifications for each prayer
- **Progress & Achievements** — Track your daily worship habits and unlock achievements
- **Rewards Shop** — Earn and spend gems by completing azkar and maintaining streaks
- **Settings** — Dark/light theme, text scaling, notification preferences, and onboarding flow
- **Bilingual** — Full Arabic and English support

## Architecture

The app follows a **feature-first** clean architecture pattern with BLoC/Cubit state management:

```
lib/
├── app/                    # Root widget, main screen with bottom navigation
├── core/
│   ├── constants/          # Spacing, preference keys
│   ├── services/           # Notification service, prayer times service, share service, timezone helper
│   └── utils/              # Shared utilities
├── data/                   # Global data (world cities)
├── features/
│   ├── azkar/              # data / domain / presentation
│   ├── onboarding/         # presentation
│   ├── prayer_times/       # data / domain / presentation
│   ├── progress/           # data / presentation
│   ├── settings/           # data / presentation
│   └── shop/               # data / presentation
├── shared/widgets/         # Reusable UI components (bottom nav, gem badge, Islamic pattern, etc.)
├── theme/                  # App colors & theme definitions
└── main.dart               # Entry point
```

Each feature is structured as:
- **data/** — Local data sources, repositories
- **domain/** — Models/entities (where applicable)
- **presentation/** — Screens, cubits, states

## Key Dependencies

| Package | Purpose |
|---|---|
| `flutter_bloc` | State management (Cubit pattern) |
| `geolocator` | Device location for prayer times |
| `adhan_dart` | Prayer time calculations |
| `hijri` | Hijri (Islamic) calendar dates |
| `flutter_local_notifications` | Prayer & azkar reminders |
| `shared_preferences` | Local key-value storage |
| `audioplayers` | Adhan/azkar audio playback |
| `confetti` | Celebration effects on achievements |
| `share_plus` | Sharing content |
| `google_fonts` | Custom typography |
| `flutter_svg` | SVG icon rendering |

## Getting Started

### Prerequisites

- Flutter SDK >= 3.9.2
- Dart SDK >= 3.9.2

### Install & Run

```bash
flutter pub get
flutter run
```

### Build

```bash
flutter build apk      # Android
flutter build ios      # iOS
flutter build web      # Web
```

## Assets

- `assets/azkar.json` / `assets/adhkar_source.json` — Azkar data
- `assets/sounds/` — Audio files (adhan, notifications)
- `assets/lang/` — Localization files (`en.json`, `ar.json`)
- `assets/icon*.png` — App icons (light, dark, foreground, notification)

## Platforms

Android, iOS, Web, Windows, macOS, Linux
