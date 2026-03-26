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
