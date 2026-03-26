# Habitual

A beautiful habit tracking app inspired by [HabitKit](https://www.habitkit.app/) with GitHub-style heatmap grids. Built natively with SwiftUI for iOS, macOS, and Apple Watch with iCloud sync across all devices.

## Screenshots

> Golden images are auto-recorded by CI via [snapshot tests](Tests/HabitualSnapshotTests/ShowcaseSnapshotTests.swift).
> See the full gallery in [`__Snapshots__/ShowcaseSnapshotTests/`](Tests/HabitualSnapshotTests/__Snapshots__/ShowcaseSnapshotTests/).

### Dashboard

| Light | Dark |
|:---:|:---:|
| ![Dashboard Light](Tests/HabitualSnapshotTests/__Snapshots__/ShowcaseSnapshotTests/testShowcase_Dashboard_Light.1.png) | ![Dashboard Dark](Tests/HabitualSnapshotTests/__Snapshots__/ShowcaseSnapshotTests/testShowcase_Dashboard_Dark.1.png) |

### Habit Detail

| Active Streak | Perfect Streak | New Habit |
|:---:|:---:|:---:|
| ![Active Streak](Tests/HabitualSnapshotTests/__Snapshots__/ShowcaseSnapshotTests/testShowcase_HabitDetail_ActiveStreak_Light.1.png) | ![Perfect Streak](Tests/HabitualSnapshotTests/__Snapshots__/ShowcaseSnapshotTests/testShowcase_HabitDetail_PerfectStreak.1.png) | ![Fresh Habit](Tests/HabitualSnapshotTests/__Snapshots__/ShowcaseSnapshotTests/testShowcase_HabitDetail_FreshHabit.1.png) |

| Dark Mode Detail |
|:---:|
| ![Detail Dark](Tests/HabitualSnapshotTests/__Snapshots__/ShowcaseSnapshotTests/testShowcase_HabitDetail_ActiveStreak_Dark.1.png) |

### Heatmaps

| 6-Month Heatmap | Multi-Color Comparison |
|:---:|:---:|
| ![Heatmap 6 Months](Tests/HabitualSnapshotTests/__Snapshots__/ShowcaseSnapshotTests/testShowcase_Heatmap_6Months.1.png) | ![Multi-Color Heatmaps](Tests/HabitualSnapshotTests/__Snapshots__/ShowcaseSnapshotTests/testShowcase_Heatmap_MultiColor.1.png) |

### Statistics & Calendar

| Statistics Grid | Calendar View |
|:---:|:---:|
| ![Stats](Tests/HabitualSnapshotTests/__Snapshots__/ShowcaseSnapshotTests/testShowcase_StatisticsGrid.1.png) | ![Calendar](Tests/HabitualSnapshotTests/__Snapshots__/ShowcaseSnapshotTests/testShowcase_CalendarView.1.png) |

### Create Habit

| Add Habit Form (Light) | Add Habit Form (Dark) |
|:---:|:---:|
| ![Add Habit Light](Tests/HabitualSnapshotTests/__Snapshots__/ShowcaseSnapshotTests/testShowcase_AddHabitForm_Light.1.png) | ![Add Habit Dark](Tests/HabitualSnapshotTests/__Snapshots__/ShowcaseSnapshotTests/testShowcase_AddHabitForm_Dark.1.png) |

| Icon Picker | Color Picker | Preview Card |
|:---:|:---:|:---:|
| ![Icons](Tests/HabitualSnapshotTests/__Snapshots__/ShowcaseSnapshotTests/testShowcase_IconPicker.1.png) | ![Colors](Tests/HabitualSnapshotTests/__Snapshots__/ShowcaseSnapshotTests/testShowcase_ColorPicker.1.png) | ![Preview](Tests/HabitualSnapshotTests/__Snapshots__/ShowcaseSnapshotTests/testShowcase_HabitPreviewCard.1.png) |

### Edit Habit

| Edit Habit Form |
|:---:|
| ![Edit Habit](Tests/HabitualSnapshotTests/__Snapshots__/ShowcaseSnapshotTests/testShowcase_EditHabitForm_Light.1.png) |

### Mascots

| Mascot Banners |
|:---:|
| ![Mascot Banners](Tests/HabitualSnapshotTests/__Snapshots__/ShowcaseSnapshotTests/testShowcase_MascotBanners.1.png) |

### Archive

| Archived Habits |
|:---:|
| ![Archive](Tests/HabitualSnapshotTests/__Snapshots__/ShowcaseSnapshotTests/testShowcase_Archive.1.png) |

### Settings & States

| Settings Light | Settings Dark | Habit Card States |
|:---:|:---:|:---:|
| ![Settings Light](Tests/HabitualSnapshotTests/__Snapshots__/ShowcaseSnapshotTests/testShowcase_Settings_Light.1.png) | ![Settings Dark](Tests/HabitualSnapshotTests/__Snapshots__/ShowcaseSnapshotTests/testShowcase_Settings_Dark.1.png) | ![Card States](Tests/HabitualSnapshotTests/__Snapshots__/ShowcaseSnapshotTests/testShowcase_HabitCardStates.1.png) |

### Empty State

| First Launch |
|:---:|
| ![Empty State](Tests/HabitualSnapshotTests/__Snapshots__/ShowcaseSnapshotTests/testShowcase_EmptyState.1.png) |

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

## Development

### Prerequisites

Install the required tools via Homebrew:

```bash
brew install swiftlint swift-format
gem install xcpretty  # for build output formatting
```

### Linting

```bash
make lint        # check for violations (strict mode)
make lint-fix    # auto-fix violations, then lint
```

### Formatting

```bash
make format        # format all Swift sources in-place
make format-check  # check formatting without modifying files
```

### Testing

```bash
make test                   # unit & integration tests
make test-snapshot          # snapshot tests (comparison mode)
make test-snapshot-record   # re-record snapshot golden images
make test-all               # unit + snapshot tests
```

Or run directly with `swift test`:

```bash
swift test --filter HabitualTests           # unit tests
swift test --filter HabitualSnapshotTests   # snapshot tests
SNAPSHOT_RECORD=true swift test --filter HabitualSnapshotTests  # re-record
```

### Build

```bash
make build  # build for iOS Simulator
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
3. Ensure iCloud capability is enabled with your CloudKit container (`iCloud.com.habitual-helper.app`)
4. Ensure App Groups is enabled (`group.com.habitual-helper.app`)
5. Build and run on your target device

## iCloud Configuration

The app uses `NSPersistentCloudKitContainer` for seamless sync:

- **CloudKit Container**: `iCloud.com.habitual-helper.app`
- **App Group**: `group.com.habitual-helper.app` (shared between app and widgets)
- **Merge Policy**: `NSMergeByPropertyObjectTrumpMergePolicy` (latest write wins)
- **History Tracking**: Enabled for remote change notifications

## License

MIT License — see [LICENSE](LICENSE) for details.
