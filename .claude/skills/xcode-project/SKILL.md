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

## Common Pitfalls

1. **Widget/watch targets missing data model** — Linker errors for `CDHabit`/`CDCompletion` symbols
2. **`codeGenerationType="manual/none"`** — Xcode crashes with assertion; omit the attribute instead
3. **Missing `.xccurrentversion`** — `DataModelCompile` silently fails; no `.momd` produced
4. **Plain `PBXFileReference` for `.xcdatamodeld`** — Must be `XCVersionGroup` for versioned models
5. **Manual CoreData files in Xcode compile sources + auto code-gen** — Duplicate symbol errors
