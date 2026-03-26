// swift-tools-version: 5.9
// The Xcode project (Habitual.xcodeproj) is the primary build system.
// This Package.swift enables SPM-based testing with `swift test`.

import PackageDescription

let package = Package(
    name: "Habitual",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10),
    ],
    products: [
        .library(
            name: "HabitualCore",
            targets: ["HabitualCore"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.15.0"),
    ],
    targets: [
        .target(
            name: "HabitualCore",
            path: "Habitual/Sources",
            exclude: ["HabitualApp.swift"],
            resources: [
                .process("Models/Habitual.xcdatamodeld"),
            ]
        ),
        .testTarget(
            name: "HabitualTests",
            dependencies: ["HabitualCore"],
            path: "Tests/HabitualTests"
        ),
        .testTarget(
            name: "HabitualSnapshotTests",
            dependencies: [
                "HabitualCore",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ],
            path: "Tests/HabitualSnapshotTests",
            exclude: ["__Snapshots__"]
        ),
    ]
)
