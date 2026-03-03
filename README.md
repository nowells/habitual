# Habitual

A beautiful habit tracking app inspired by [HabitKit](https://www.habitkit.app/) with GitHub-style heatmap grids. Built natively with SwiftUI for iOS, macOS, and Apple Watch with iCloud sync across all devices.

## Features

### Core Habit Tracking
- **GitHub-style heatmap grids** — Visual progress tracking with color-coded completion grids
- **Flexible goals** — Set daily, weekly, or monthly frequency targets (e.g., 3x/week)
- **Streaks** — Current and longest streak tracking for motivation
- **Calendar view** — Tap any day to toggle completions, manage past entries easily
- **Statistics** — Completion rate, total completions, streak data at a glance
- **Smart reminders** — Schedule daily notifications for each habit
- **Archive** — Hide habits temporarily without losing data

### Customization
- **40+ SF Symbol icons** to personalize each habit
- **12 preset colors** for visual differentiation
- **Themes** — System, Light, and Dark mode support
- **Configurable heatmap range** — 3, 4, 6, or 12 months

### Multi-Platform
- **iOS** — Full-featured iPhone and iPad app
- **macOS** — Native Mac app via Mac Catalyst
- **watchOS** — Apple Watch companion with quick completions and mini heatmaps

### Widgets
- **Home Screen widgets** (Small, Medium, Large) — Daily progress, habit list, mini heatmaps
- **Lock Screen widgets** — Circular, rectangular, and inline formats
- **Single Habit widget** — Focus on one habit with a dedicated heatmap
- **Watch complications** — Circular, rectangular, inline, and corner styles

### iCloud Sync
- **CloudKit integration** — All data syncs automatically across devices
- **Shared App Group** — Widgets have real-time access to habit data
- **Automatic merge** — Conflict-free sync with property-level merge policy

## Architecture

```
Habitual/
├── Sources/
│   ├── HabitualApp.swift           # App entry point
│   ├── Models/
│   │   ├── Habit.swift             # Value types, Core Data conversions, business logic
│   │   ├── Persistence.swift       # Core Data + CloudKit stack
│   │   └── Habitual.xcdatamodeld   # Core Data schema
│   ├── ViewModels/
│   │   └── HabitStore.swift        # Observable data store
│   ├── Views/
│   │   ├── ContentView.swift       # Main dashboard
│   │   ├── Components/
│   │   │   ├── HeatmapGridView.swift   # GitHub-style heatmap
│   │   │   └── HabitCardView.swift     # Habit card with mini heatmap
│   │   ├── Habits/
│   │   │   ├── AddHabitView.swift      # Create new habit
│   │   │   ├── EditHabitView.swift     # Edit existing habit
│   │   │   └── HabitDetailView.swift   # Full detail with calendar + stats
│   │   └── Settings/
│   │       └── SettingsView.swift      # App preferences
│   ├── Services/
│   │   └── NotificationService.swift   # Local notification scheduling
│   ├── Extensions/
│   │   └── Color+Extensions.swift      # Cross-platform color helpers
│   └── Utilities/
│       └── WidgetUpdateService.swift   # Widget timeline refresh
├── Resources/
│   ├── Assets.xcassets
│   ├── Habitual.entitlements
│   └── Info.plist
HabitualWatch/
├── Sources/
│   ├── HabitualWatchApp.swift
│   ├── Views/WatchContentView.swift
│   └── Complications/HabitualComplications.swift
HabitualWidgets/
├── Sources/
│   └── HabitualWidgets.swift       # All widget sizes + lock screen
└── Resources/
    └── HabitualWidgets.entitlements
```

## Requirements

- Xcode 15.3+
- iOS 17.0+
- macOS 14.0+
- watchOS 10.0+
- Apple Developer account (for CloudKit and iCloud entitlements)

## Setup

1. Open `Habitual.xcodeproj` in Xcode
2. Set your Development Team in each target's Signing & Capabilities
3. Ensure iCloud capability is enabled with your CloudKit container (`iCloud.com.habitual.app`)
4. Ensure App Groups is enabled (`group.com.habitual.app`)
5. Build and run on your target device

## iCloud Configuration

The app uses `NSPersistentCloudKitContainer` for seamless sync:

- **CloudKit Container**: `iCloud.com.habitual.app`
- **App Group**: `group.com.habitual.app` (shared between app and widgets)
- **Merge Policy**: `NSMergeByPropertyObjectTrumpMergePolicy` (latest write wins)
- **History Tracking**: Enabled for remote change notifications

## License

MIT License — see [LICENSE](LICENSE) for details.
