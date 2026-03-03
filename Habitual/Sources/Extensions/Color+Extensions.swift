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

// Cross-platform Color init from system colors
extension Color {
    #if os(watchOS)
    init(_ name: SystemColorName) {
        switch name {
        case .systemGray3: self = Color.gray.opacity(0.5)
        case .systemGray5: self = Color.gray.opacity(0.3)
        case .systemGray6: self = Color.gray.opacity(0.2)
        }
    }

    enum SystemColorName {
        case systemGray3, systemGray5, systemGray6
    }
    #endif
}
