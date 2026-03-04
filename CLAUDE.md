# Habitual — Claude Code Project Instructions

## Project Overview

Habitual is a multi-platform (iOS, macOS, watchOS) habit tracking app with iCloud sync via CloudKit. It uses:

- **SwiftUI** for UI across all platforms
- **CoreData + CloudKit** for persistence and sync (`NSPersistentCloudKitContainer`)
- **Dual build systems**: Xcode project (primary) and SPM `Package.swift` (testing)
- **swift-snapshot-testing** for visual regression tests (VRT)
- **GitHub Actions** CI with unit tests, snapshot tests, and build validation

## Architecture

```
Habitual.xcodeproj          ← Primary build (iOS, watchOS, widgets, complications)
Package.swift               ← SPM for `swift test` (unit + snapshot tests)
Habitual/Sources/           ← Shared source (HabitualCore SPM target)
Tests/HabitualTests/        ← Unit & integration tests
Tests/HabitualSnapshotTests/ ← Visual regression snapshot tests
.github/workflows/ci.yml    ← CI pipeline
```

## Critical Rules

### CoreData + SPM (see .claude/skills/coredata-spm.md)
- ALWAYS load CoreData models via explicit `NSManagedObjectModel` — never rely on `NSPersistentCloudKitContainer(name:)` alone
- ALWAYS provide a programmatic model fallback for SPM test contexts
- ALWAYS mark Date/UUID attributes as optional when using `usedWithCloudKit="YES"`

### Snapshot Testing (see .claude/skills/snapshot-testing.md)
- ALWAYS use deterministic test data (fixed dates, UUIDs) — never `Date()` or `UUID()`
- ALWAYS use `SnapshotContainer` to wrap views with consistent sizing
- ALWAYS subclass `SnapshotTestCase` which handles `SNAPSHOT_RECORD` env var
- ALWAYS mark snapshot test classes `@MainActor` (required for HabitStore)

### Xcode Project (see .claude/skills/xcode-project.md)
- ALL targets that compile shared source files MUST include the `.xcdatamodeld` in their build phases
- CoreData code generation: use `codeGenerationType="class"` in `.xcdatamodel` XML — NEVER use `"manual/none"` string value (Xcode crashes)
- Versioned data models require both `XCVersionGroup` file reference AND `.xccurrentversion` plist

### CI (see .claude/skills/ci-workflow.md)
- Unit tests: `swift test --filter HabitualTests`
- Snapshot tests: `swift test --filter HabitualSnapshotTests`
- Build check: `xcodebuild` with code signing disabled
- Snapshot recording: `SNAPSHOT_RECORD=true` env var triggers re-recording

## Running Tests Locally

```bash
# Unit tests
swift test --filter HabitualTests

# Snapshot tests (compare mode)
swift test --filter HabitualSnapshotTests

# Snapshot tests (re-record golden images)
SNAPSHOT_RECORD=true swift test --filter HabitualSnapshotTests
```

## Platform Compatibility

- Use `Color.systemBackground` (custom extension) instead of `Color(.systemBackground)` for macOS compatibility
- Use `#if os(macOS)` / `#if os(iOS)` guards for platform-specific code
- The macOS snapshot shim in `SnapshotTestHelpers.swift` bridges SwiftUI views to `NSHostingView`
- `#Preview` macros need `#if !os(macOS)` guards if they use iOS-only APIs
