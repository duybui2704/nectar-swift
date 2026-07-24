import SwiftUI

/// Design tokens inspired by PostPay brand blue, kept banking-safe.
enum BankColors {
    static let brand = Color(hex: 0x0A4BB3)
    static let brandSoft = Color(hex: 0xE8F0FA)
    static let navy = Color(hex: 0x0A4BB3)
    static let navySoft = Color(hex: 0x1D5FC4)
    static let teal = Color(hex: 0x0A4BB3)
    static let tealSoft = Color(hex: 0xE8F0FA)
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
