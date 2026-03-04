# Skill: Swift 6 Concurrency & Actor Isolation

## Context

This project uses strict Swift concurrency checking. `HabitStore` is `@MainActor` isolated because it drives SwiftUI views with `@Published` properties.

## Rules

### Test Classes Using HabitStore Must Be @MainActor

```swift
// GOOD — compiles with strict concurrency
@MainActor
final class MyTests: XCTestCase {
    func testSomething() {
        let store = HabitStore(...)
        // Can access store properties directly
    }
}

// BAD — "main actor-isolated property cannot be referenced from a non-isolated autoclosure"
final class MyTests: XCTestCase {
    func testSomething() {
        let store = HabitStore(...) // ← Compile error
    }
}
```

### Removing @MainActor Is NOT the Fix for Concurrency Warnings

When you see Swift 6 forward-compatibility *warnings* about `@MainActor` on test classes, do NOT remove the annotation. The warning is acceptable; the compilation error from removing it is not.

### Preview Providers and @MainActor

`#Preview` macros that create `HabitStore` instances implicitly run on the main actor. No special annotation needed for previews — but guard platform-specific previews:

```swift
#if !os(macOS)
#Preview {
    ContentView()
        .environment(\.managedObjectContext, ...)
}
#endif
```

## Common Pitfalls

1. **Removing `@MainActor` to silence warnings** — Causes hard compilation errors; keep the annotation
2. **Accessing `@MainActor` properties from non-isolated context** — Use `@MainActor` on the calling class or `await MainActor.run {}`
3. **`#Preview` with iOS-only APIs on macOS** — Gate with `#if !os(macOS)`
