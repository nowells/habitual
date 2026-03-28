import SwiftUI

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

extension Color {
    /// Cross-platform system background color
    #if os(watchOS)
        static let systemBackground = Color.black
        static let secondarySystemBackground = Color(.darkGray)
    #elseif canImport(UIKit)
        static let systemBackground = Color(UIColor.systemBackground)
        static let secondarySystemBackground = Color(UIColor.secondarySystemBackground)
    #else
        static let systemBackground = Color(NSColor.windowBackgroundColor)
        static let secondarySystemBackground = Color(NSColor.controlBackgroundColor)
    #endif
}

// Cross-platform system gray colors
extension Color {
    #if canImport(UIKit) && !os(watchOS)
        static let systemGray3 = Color(UIColor.systemGray3)
        static let systemGray5 = Color(UIColor.systemGray5)
        static let systemGray6 = Color(UIColor.systemGray6)
    #elseif canImport(AppKit)
        static let systemGray3 = Color(NSColor.tertiaryLabelColor)
        static let systemGray5 = Color(NSColor.tertiarySystemFill)
        static let systemGray6 = Color(NSColor.controlBackgroundColor)
    #else
        static let systemGray3 = Color.gray.opacity(0.5)
        static let systemGray5 = Color.gray.opacity(0.3)
        static let systemGray6 = Color.gray.opacity(0.2)
    #endif
}

// MARK: - Dark Theme Colors (GitHub-style)

extension Color {
    /// App background: near-black with blue tint (#010409)
    static let habitualBackground = Color(red: 0.004, green: 0.016, blue: 0.035)
    /// Card/section background: dark gray with blue tint (#0D1117)
    static let habitualCardBackground = Color(red: 0.051, green: 0.067, blue: 0.090)
    /// Borders (#21262D)
    static let habitualBorder = Color(red: 0.129, green: 0.149, blue: 0.176)
    /// Primary text (#E6EDF3)
    static let habitualPrimaryText = Color(red: 0.902, green: 0.929, blue: 0.953)
    /// Secondary text (#8B949E)
    static let habitualSecondaryText = Color(red: 0.545, green: 0.580, blue: 0.620)
    /// Dim text (#484F58)
    static let habitualDimText = Color(red: 0.282, green: 0.310, blue: 0.345)
    /// Broke streak red (#EF4444)
    static let habitualBrokeRed = Color(red: 0.937, green: 0.267, blue: 0.267)
}
