import SwiftUI

/// Nectar grocery design tokens — primary green from the product UI.
enum NectarColors {
    static let brand = Color(hex: 0x53B175)
    static let brandSoft = Color(hex: 0xEBF8F0)
    static let navy = Color(hex: 0x181725)
    static let navySoft = Color(hex: 0x2E2C3A)
    static let teal = Color(hex: 0x53B175)
    static let tealSoft = Color(hex: 0xEBF8F0)
    static let background = Color(hex: 0xF2F2F2)
    static let surface = Color.white
    static let textPrimary = Color(hex: 0x292D32)
    static let textSecondary = Color(hex: 0x9FA1A3)
    static let danger = Color(hex: 0xF71818)
    static let success = Color(hex: 0x0FCB67)
    static let warning = Color(hex: 0xD97706)
    static let border = Color(hex: 0xE5E7EB)
    static let cardGold = Color(hex: 0xC9A227)
    static let inputBackground = Color(hex: 0xF7F8FA)
    static let green = Color(hex: 0x53B175)
    static let googleBlue = Color(hex: 0x5383EC)
    static let facebookBlue = Color(hex: 0x4A66AC)
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
