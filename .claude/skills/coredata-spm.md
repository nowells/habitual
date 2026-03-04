# Skill: CoreData with SPM and CloudKit

## Problem

CoreData's `.xcdatamodeld` files are designed for Xcode's build system. SPM's `.process()` resource rule does NOT reliably compile them into `.momd` via `momc`. This causes crashes in `swift test` when CoreData models can't be found.

Additionally, CloudKit compatibility (`usedWithCloudKit="YES"`) imposes validation rules that `momc` enforces at compile time.

## Approach: Three-Strategy Model Loading

Always load CoreData models using a cascading fallback in `Persistence.swift`:

```swift
static let managedObjectModel: NSManagedObjectModel = {
    // 1. Try compiled .momd/.mom from Bundle.module (SPM) or Bundle.main (Xcode)
    let bundles: [Bundle] = {
        #if SWIFT_PACKAGE
        return [Bundle.module, Bundle.main]
        #else
        return [Bundle.main]
        #endif
    }()

    for bundle in bundles {
        if let url = bundle.url(forResource: name, withExtension: "momd")
            ?? bundle.url(forResource: name, withExtension: "mom"),
           let model = NSManagedObjectModel(contentsOf: url) {
            return model
        }
        // 2. Try merged model discovery
        if let model = NSManagedObjectModel.mergedModel(from: [bundle]),
           !model.entities.isEmpty {
            return model
        }
    }

    // 3. Build programmatically (SPM fallback)
    return buildManagedObjectModel()
}()
```

Then always initialize the container with the explicit model:
```swift
container = NSPersistentCloudKitContainer(
    name: containerName,
    managedObjectModel: Self.managedObjectModel
)
```

## Programmatic Model Rules

When building `NSManagedObjectModel` in code:
- Use `NSAttributeType` enum values (e.g., `.stringAttributeType`, `.dateAttributeType`) — NOT `NSAttributeDescription.AttributeType` which doesn't exist
- Set relationship inverses on both sides
- Match attribute names, types, defaults, and optionality exactly to the `.xcdatamodel` XML

## CloudKit Compatibility Rules

When `usedWithCloudKit="YES"` is set in the data model:
- `momc` enforces that non-optional attributes MUST have default values
- `Date` and `UUID` attributes should be marked `optional="YES"` in the model XML
- This is a no-op for runtime behavior (Swift properties are already `Optional`) but satisfies CloudKit validation
- Without this, `DataModelCompile` fails with: `error: attribute must be optional or have a default value`

## Common Pitfalls

1. **`NSPersistentCloudKitContainer(name:)` alone** — searches only `Bundle.main`, fails in SPM test context
2. **`Bundle.module` in non-SPM builds** — doesn't exist; guard with `#if SWIFT_PACKAGE`
3. **`NSAttributeDescription.AttributeType`** — doesn't exist in the CoreData SDK; use `NSAttributeType`
4. **`codeGenerationType="manual/none"` in XML** — causes Xcode assertion crash; omit the attribute entirely for manual code gen
5. **`codeGenerationType="class"` with manual files in build** — causes duplicate symbols; keep manual files for SPM but exclude from Xcode compile sources
