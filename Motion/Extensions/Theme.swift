//
//  Theme.swift
//  Motion
//
//  Design tokens (colors, gradients) and shared view modifiers.
//  Developed by Kas-Kazini Inc.
//

import SwiftUI

extension Color {
    /// Creates a color from a 24-bit hex value, e.g. `Color(hex: 0xFF5A1F)`.
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

/// Central place for the Motion visual identity: dark surfaces + energetic orange.
enum Theme {
    static let brand = Color(hex: 0xFF5A1F)
    static let brandLight = Color(hex: 0xFF8A4C)
    static let electricBlue = Color(hex: 0x2D7BFF)
    static let success = Color(hex: 0x34C759)
    static let danger = Color(hex: 0xFF453A)

    static let background = Color(hex: 0x0B0B0D)
    static let card = Color(hex: 0x17171B)
    static let cardElevated = Color(hex: 0x24242B)
    static let textSecondary = Color(hex: 0x9A9AA5)

    static let brandGradient = LinearGradient(
        colors: [brandLight, Color(hex: 0xFF3D00)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

/// Rounded dark card container.
struct CardModifier: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

extension View {
    func cardStyle(padding: CGFloat = 16) -> some View {
        modifier(CardModifier(padding: padding))
    }
}
