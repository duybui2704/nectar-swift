import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum NectarColorMap {
    private static let colors: [String: Color] = [
        "black": .black,
        "white": .white,
        "red": .red,
        "purple": .purple,
        "blue": .blue,
        "green": .green,
        "yellow": .yellow,
        "orange": .orange,
        "pink": .pink,
        "gray": .gray,
        "grey": .gray,
        "cyan": .cyan,
        "mint": .mint,
        "teal": .teal,
        "indigo": .indigo,
        "brown": .brown,
        "clear": .clear,

        "navy": Color(hex: 0x001F3F),
        "royal": Color(hex: 0x4169E1),
        "royal blue": Color(hex: 0x4169E1),
        "light blue": .cyan,
        "sky blue": Color(hex: 0x87CEEB),
        "forest green": Color(hex: 0x228B22),
        "irish green": Color(hex: 0x009A44),
        "maroon": Color(hex: 0x800000),
        "cardinal red": Color(hex: 0xC41E3A),
        "gold": Color(hex: 0xD4AF37),
        "charcoal": Color(hex: 0x36454F),
        "asphalt": Color(hex: 0x3D3D3D),
        "ash": Color(hex: 0xB2BEB5),
        "beige": Color(hex: 0xF5F5DC),
        "cream": Color(hex: 0xFFFDD0),
        "ivory": Color(hex: 0xFFFFF0),
        "khaki": Color(hex: 0xC3B091),
        "olive": Color(hex: 0x808000),
        "burgundy": Color(hex: 0x800020),
        "coral": Color(hex: 0xFF7F50),
        "turquoise": Color(hex: 0x40E0D0),
        "lavender": Color(hex: 0xE6E6FA),
        "magenta": Color(hex: 0xFF00FF),
        "silver": Color(hex: 0xC0C0C0),
        "heather grey": Color(hex: 0x9B9B9B),
        "heather gray": Color(hex: 0x9B9B9B),
        "dark heather": Color(hex: 0x6B6B6B),
        "sport grey": Color(hex: 0x9B9B9B),
        "sport gray": Color(hex: 0x9B9B9B),
    ]

    static func color(named raw: String?) -> Color? {
        guard let raw else { return nil }
        let key = normalize(raw)
        guard !key.isEmpty else { return nil }

        if let exact = colors[key] { return exact }

        let compact = key.replacingOccurrences(of: " ", with: "")
        if let hit = colors.first(where: {
            $0.key.replacingOccurrences(of: " ", with: "") == compact
        })?.value {
            return hit
        }

        // "Dark Navy Blue" → ưu tiên key dài nhất nằm trong tên
        let partial = colors
            .filter { key.contains($0.key) && !$0.key.isEmpty }
            .max(by: { $0.key.count < $1.key.count })
        return partial?.value
    }

    /// Ưu tiên **tên** (RN `item.name`), rồi hex, rồi thử parse `hex` như tên (API hay nhét name vào field color).
    static func resolve(name: String?, hex: String?) -> Color {
        if let named = color(named: name) { return named }
        if let hex {
            if let value = parseHex(hex) { return Color(hex: value) }
            if let namedFromHexField = color(named: hex) { return namedFromHexField }
        }
        return .gray
    }

    static func normalize(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    static func parseHex(_ raw: String) -> UInt? {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard (s.count == 6 || s.count == 8),
              let value = UInt(String(s.prefix(6)), radix: 16) else {
            return nil
        }
        return value
    }

    /// Checkmark trên nền sáng → chữ tối; nền tối → chữ trắng.
    static func contrastingForeground(for fill: Color) -> Color {
        #if canImport(UIKit)
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        guard UIColor(fill).getRed(&r, green: &g, blue: &b, alpha: &a) else {
            return .white
        }
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance > 0.65 ? NectarColors.textPrimary : .white
        #else
        return .white
        #endif
    }
}
