import SwiftUI

/// Config skeleton toàn app — màu / tốc độ shimmer.
enum SkeletonStyle {
    /// Nền xương.
    static let base = Color(hex: 0xE8E8ED)
    /// Highlight shimmer.
    static let highlight = Color.white.opacity(0.65)
    /// Viền / surface nhạt.
    static let surface = Color(hex: 0xF2F2F7)

    static let animationDuration: Double = 1.35
    static let cornerSmall: CGFloat = 6
    static let cornerMedium: CGFloat = NectarMetrics.radius.md
    static let cornerLarge: CGFloat = NectarMetrics.radius.lg
}
