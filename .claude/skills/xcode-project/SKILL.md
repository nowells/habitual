---
name: xcode-project
description: Guidelines for Xcode project structure with multi-target CoreData apps. Use when modifying the Xcode project, adding targets, or fixing build errors related to CoreData code generation.
---

# Skill: Xcode Project Structure for Multi-Target Apps

## Architecture

This project has multiple Xcode targets that share source code:

- **Habitual** (iOS app) — main target
- **HabitualWatch** (watchOS app)
- **HabitualWidget** (widget extension)
- **HabitualComplications** (watch complications)

All targets compile shared source files (`HabitStore.swift`, `Habit.swift`, etc.) that reference CoreData managed objects (`CDHabit`, `CDCompletion`).

## CoreData Model in Multi-Target Projects

### Rule: Every target that compiles CoreData-referencing source MUST include the `.xcdatamodeld`

If a target compiles files that reference `CDHabit` or `CDCompletion` but doesn't have the data model in its "Compile Sources" build phase, it will fail with undefined symbol errors.

When adding the data model to a target's build phase, ensure:
1. The `.xcdatamodeld` is listed in the target's `PBXSourcesBuildPhase`
2. The file reference uses `XCVersionGroup` (not plain `PBXFileReference`)
3. The `.xccurrentversion` plist file exists inside the `.xcdatamodeld` directory

### `.xccurrentversion` Plist

This file MUST exist at `Model.xcdatamodeld/.xccurrentversion`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>_XCCurrentVersionName</key>
    <string>Habitual.xcdatamodel</string>
</dict>
</plist>
```

Without it, Xcode's `DataModelCompile` phase fails silently or produces no output.

## CoreData Code Generation Modes

### `codeGenerationType` in `.xcdatamodel` XML

| Value in XML | Behavior |
|---|---|
| `"class"` | Xcode auto-generates managed object subclasses at build time |
| Attribute **omitted** | Manual code generation (you provide the Swift files) |
| `"manual/none"` | **CRASHES XCODE** — assertion failure in build system |

### Dual Build System Strategy

Since Xcode auto-generates classes with `codeGenerationType="class"` but SPM doesn't:

1. Keep `codeGenerationType="class"` in the `.xcdatamodel` (for Xcode builds)
2. Keep manual `CDHabit+CoreDataClass.swift` / `CDHabit+CoreDataProperties.swift` files in the repo (for SPM builds)
3. **Remove** the manual files from Xcode's "Compile Sources" build phase to avoid duplicate symbols
4. SPM picks up the manual files via the target's `path` directive

## Adding New Swift Files to the Xcode Project

The Xcode project does **NOT** automatically pick up new `.swift` files placed on disk. Every new file must be manually registered in `Habitual.xcodeproj/project.pbxproj`. Forgetting this causes "cannot find type in scope" errors in every file that imports the new type, even though `swift test` (SPM) works fine.

### GUID Naming Convention

This project uses short, human-readable GUIDs:

| Prefix | Section | Example |
|--------|---------|---------|
| `A1xxxx` | PBXBuildFile (main Habitual target) | `A10023` |
| `B1xxxx` | PBXFileReference (shared files) | `B10023` |
| `D11xxx` | PBXGroup | `D11011` |

When picking new GUIDs, increment the last existing number in each section (e.g. after `A10022`, use `A10023`).

### Three Sections to Update

For each new Swift source file, add entries to **three** sections of `project.pbxproj`:

#### 1. PBXFileReference — declare the file exists

```
B10023 /* NudgeService.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = NudgeService.swift; sourceTree = "<group>"; };
```

- `path` is just the **filename**, not the full path (the group provides directory context)
- `sourceTree = "<group>"` is always correct for project-relative source files

#### 2. PBXBuildFile — wire it into a target's compile step

```
A10023 /* NudgeService.swift in Sources */ = {isa = PBXBuildFile; fileRef = B10023; };
```

#### 3a. PBXGroup — add it to the correct folder group

Find the group whose `path` matches the directory the file lives in and add the fileRef to its `children`:

```
D11005 /* Services */ = {
    isa = PBXGroup;
    children = (
        B10012 /* NotificationService.swift */,
        B10023 /* NudgeService.swift */,   ← add here
    );
    path = Services;
    sourceTree = "<group>";
};
```

If the file lives in a **new directory** with no existing group, create a new `PBXGroup` entry and add it as a child of its parent group:

```
D11011 /* AppIntents */ = {
    isa = PBXGroup;
    children = (
        B10024 /* HabitIntents.swift */,
    );
    path = AppIntents;
    sourceTree = "<group>";
};
```

Then add `D11011 /* AppIntents */,` to the parent group's `children` list.

#### 3b. PBXSourcesBuildPhase — add it to the target's compile sources list

```
F10001 /* Sources */ = {
    isa = PBXSourcesBuildPhase;
    ...
    files = (
        ...
        A10023 /* NudgeService.swift in Sources */,   ← add here
    );
};
```

The main Habitual target's build phase is `F10001`. Other targets (`F20001` watch, `F30001` widgets, `F40001` complications) have their own build phases.

### Checklist for adding a new file

- [ ] `PBXFileReference` entry added (`B1xxxx`)
- [ ] `PBXBuildFile` entry added (`A1xxxx`) for each target that needs it
- [ ] File's `fileRef` added to the correct `PBXGroup` children list
- [ ] New directory → new `PBXGroup` created and added to parent group children
- [ ] `PBXBuildFile` added to the correct target's `PBXSourcesBuildPhase`
- [ ] If shared across watch/widget targets, add corresponding `A2xxxx`/`A3xxxx` build files and update those targets' build phases too

### System Frameworks (no explicit linking needed)

System frameworks imported via `import FrameworkName` in Swift are auto-linked by the linker — no `PBXFrameworksBuildPhase` entry required for:

- `UserNotifications`
- `AppIntents`
- `WidgetKit`
- `CoreData`
- `CloudKit`

## Common Pitfalls

1. **Widget/watch targets missing data model** — Linker errors for `CDHabit`/`CDCompletion` symbols
2. **`codeGenerationType="manual/none"`** — Xcode crashes with assertion; omit the attribute instead
3. **Missing `.xccurrentversion`** — `DataModelCompile` silently fails; no `.momd` produced
4. **Plain `PBXFileReference` for `.xcdatamodeld`** — Must be `XCVersionGroup` for versioned models
5. **Manual CoreData files in Xcode compile sources + auto code-gen** — Duplicate symbol errors
6. **New `.swift` file on disk but not in `project.pbxproj`** — SPM (`swift test`) builds fine but `xcodebuild` fails with "cannot find type in scope" in every file that imports the missing type; fix by adding PBXFileReference + PBXBuildFile + PBXGroup + PBXSourcesBuildPhase entries
