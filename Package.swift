// swift-tools-version: 5.9
// This Package.swift provides structure reference for the project.
// The actual build is managed through the Xcode project (Habitual.xcodeproj).

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
    targets: [
        .target(
            name: "HabitualCore",
            path: "Habitual/Sources",
            exclude: ["HabitualApp.swift"],
            resources: [
                .process("Models/Habitual.xcdatamodeld"),
            ]
        ),
    ]
)
