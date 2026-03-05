---
name: snapshot-testing
description: Guidelines for writing SwiftUI snapshot tests with deterministic data, SnapshotContainer, and cross-platform compatibility. Use when creating or modifying snapshot tests.
---

# Skill: SwiftUI Snapshot Testing (VRT)

## Setup

This project uses [swift-snapshot-testing](https://github.com/pointfreeco/swift-snapshot-testing) for visual regression testing.

### Test Infrastructure

- **`SnapshotTestCase`** — Base class that reads `SNAPSHOT_RECORD` env var to toggle recording mode
- **`SnapshotContainer`** — SwiftUI wrapper that provides consistent sizing and background
- **`TestData`** — Deterministic test data factory with fixed dates, UUIDs, and sample habits
- **macOS shim** — `Snapshotting<SwiftUI.View, NSImage>` extension bridges SwiftUI to `NSHostingView` on macOS

### File Structure

```
Tests/HabitualSnapshotTests/
  SnapshotTestHelpers.swift      ← Base class, TestData, SnapshotContainer, macOS shim
  ContentViewSnapshotTests.swift ← Focused component tests
  ShowcaseSnapshotTests.swift    ← Full-screen showcase tests (for README gallery)
  DetailViewSnapshotTests.swift  ← Detail view tests
  HeatmapSnapshotTests.swift    ← Heatmap visualization tests
  HabitCardSnapshotTests.swift  ← Habit card states
  SettingsSnapshotTests.swift   ← Settings screen tests
  __Snapshots__/                ← Golden reference images (auto-generated)
```

## Rules for Writing Snapshot Tests

### 1. Always Use Deterministic Data

NEVER use `Date()`, `UUID()`, or any non-deterministic values. Always use `TestData`:

```swift
// GOOD
let habit = TestData.exerciseHabit
let date = TestData.date(daysAgo: 5)

// BAD — will produce different snapshots every run
let habit = Habit(id: UUID(), createdAt: Date(), ...)
```

### 2. Always Use SnapshotContainer

Wrap views in `SnapshotContainer` for consistent sizing:

```swift
assertSnapshot(of: SnapshotContainer(width: 390, height: 200) {
    HabitCard(habit: TestData.exerciseHabit)
}, as: .image)
```

### 3. Always Subclass SnapshotTestCase

```swift
@MainActor
final class MySnapshotTests: SnapshotTestCase {
    func testMyView() {
        assertSnapshot(of: ..., as: .image)
    }
}
```

The `@MainActor` annotation is required because `HabitStore` is `@MainActor` isolated.

### 4. Two Test Categories

- **Focused component tests**: Test individual components at specific sizes, states, edge cases
- **Showcase tests**: Full-screen renders designed for README documentation gallery

### 5. Recording vs Comparing

- **Compare mode** (default): Tests fail if rendered image differs from golden reference
- **Record mode**: `SNAPSHOT_RECORD=true` — overwrites golden images with current renders
- CI automatically re-records and commits on PRs when snapshots fail

### 6. Color Compatibility

Use `Color.systemBackground` (custom extension) instead of `Color(.systemBackground)`:
```swift
// GOOD — works on macOS and iOS
.background(Color.systemBackground)

// BAD — Color(.systemBackground) doesn't compile on macOS
.background(Color(.systemBackground))
```

## Common Pitfalls

1. **Missing `@MainActor`** — Compilation error: "main actor-isolated property cannot be referenced from a non-isolated autoclosure"
2. **Non-deterministic data** — Snapshots differ on every run, tests are flaky
3. **Hardcoded `isRecording = true`** — Accidentally committed; tests never catch regressions. Always use `SNAPSHOT_RECORD` env var via `SnapshotTestCase`
4. **Platform-specific colors** — `UIColor` references don't compile on macOS
5. **Missing macOS shim** — `Snapshotting<SwiftUI.View, NSImage>.image(layout:)` doesn't exist in the library; our shim in `SnapshotTestHelpers.swift` provides it
6. **`List`/`Form` reports zero height** — SwiftUI `List` and `Form` are lazy scroll containers; `NSHostingView.fittingSize` returns `(width, 0)` for them. Always provide an explicit `height` in `SnapshotContainer` for any view whose root is a `List`, `Form`, or `ArchiveView`/`SettingsView`/`AddHabitView`/`EditHabitView`. Reference heights: AddHabitView ≈ 1000pt, EditHabitView ≈ 1100pt, SettingsView ≈ 700pt, ArchiveView (3 items) ≈ 300pt.
7. **`NavigationStack` breaks layout on macOS** — `NavigationStack` uses macOS-native navigation layout (not iOS-style) and misplaces form content. Never wrap snapshot views in `NavigationStack`; the `.navigationTitle` and `.toolbar` modifiers become no-ops but the form content renders correctly.
8. **macOS `List` renders blank rows** — `NSTableView` (which backs SwiftUI `List` on macOS) populates cells asynchronously. Without a runloop drain, the snapshot captures empty rows. The macOS shim runs `RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))` before the final `layoutSubtreeIfNeeded()` to allow rows to populate — no action needed in tests.
9. **macOS `Form` two-column layout squishes controls** — On macOS, `Form` defaults to a two-column label+control style. Long TextField placeholder strings become left-column labels, leaving very little width for the actual controls. `SnapshotContainer` applies `.formStyle(.grouped)` on macOS automatically to get iOS-style full-width rows — no action needed in tests.
