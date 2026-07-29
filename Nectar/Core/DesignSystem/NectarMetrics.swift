import SwiftUI
import UIKit

/// Scale size theo chiều rộng màn hình — áp dụng thống nhất mọi iPhone.
///
/// Design base: **iPhone 14 / 15** = 390pt width.
/// - iPhone SE (375) ≈ 0.96×
/// - iPhone 14 Pro Max (430) ≈ 1.10× (cap 1.15 để không phình quá)
///
/// Cách dùng:
/// ```swift
/// .padding(NectarMetrics.spacing.lg)
/// .font(NectarTypography.title)
/// .frame(height: NectarMetrics.button.primaryHeight)
/// Text("Hi").font(.system(size: 28.scaled))
/// ```
enum NectarMetrics {

    // MARK: - Scale

    /// Chiều rộng thiết kế Figma / mock (iPhone 14).
    static let designWidth: CGFloat = 390

    /// Scale hiện tại (đọc từ window / screen).
    static var scale: CGFloat {
        let width = UIScreen.main.bounds.width
        let raw = width / designWidth
        // Không thu nhỏ dưới 0.90 (SE), không phóng quá 1.15 (Pro Max)
        return min(max(raw, 0.90), 1.15)
    }

    /// Scale một giá trị pt từ design.
    static func s(_ value: CGFloat) -> CGFloat {
        (value * scale).rounded(.toNearestOrAwayFromZero)
    }

    // MARK: - Spacing (padding / gap)
    // Dùng `struct` (không dùng `enum`) vì cần khởi tạo `Spacing()`.

    struct Spacing {
        var xxxs: CGFloat { NectarMetrics.s(4) }
        var xxs: CGFloat { NectarMetrics.s(8) }
        var xs: CGFloat { NectarMetrics.s(12) }
        var sm: CGFloat { NectarMetrics.s(16) }
        var md: CGFloat { NectarMetrics.s(20) }
        var lg: CGFloat { NectarMetrics.s(24) }
        var xl: CGFloat { NectarMetrics.s(32) }
        var xxl: CGFloat { NectarMetrics.s(40) }
        var xxxl: CGFloat { NectarMetrics.s(48) }
    }

    static let spacing = Spacing()

    // MARK: - Corner radius

    struct Radius {
        var sm: CGFloat { NectarMetrics.s(8) }
        var md: CGFloat { NectarMetrics.s(12) }
        var lg: CGFloat { NectarMetrics.s(16) }
        var xl: CGFloat { NectarMetrics.s(22) }
        var pill: CGFloat { 999 }
    }

    static let radius = Radius()

    // MARK: - Icon / Illustration

    struct Icon {
        var sm: CGFloat { NectarMetrics.s(20) }
        var md: CGFloat { NectarMetrics.s(24) }
        var lg: CGFloat { NectarMetrics.s(32) }
        var xl: CGFloat { NectarMetrics.s(48) }
        var hero: CGFloat { NectarMetrics.s(64) }
        var splashWidth: CGFloat { NectarMetrics.s(267) }
        var splashHeight: CGFloat { NectarMetrics.s(69) }
        var width: CGFloat { NectarMetrics.s(UIScreen.main.bounds.width) }
        /// Chiều rộng illustration onboarding (~70% màn hình, cap hợp lý).
        var onboardingWidth: CGFloat {
            min(UIScreen.main.bounds.width, NectarMetrics.s(UIScreen.main.bounds.height * 0.72))
        }
    }

    static let icon = Icon()

    // MARK: - Button

    struct Button {
        /// Chiều cao nút mặc định trên app.
        var primaryHeight: CGFloat { NectarMetrics.s(45) }
        var cornerRadius: CGFloat { NectarMetrics.s(12) }
        /// Design Onboarding dùng 67 — giữ đúng tỷ lệ.
        var onboardingHeight: CGFloat { NectarMetrics.s(67) }
        var secondaryHeight: CGFloat { NectarMetrics.s(48) }
        var horizontalPadding: CGFloat { NectarMetrics.spacing.lg }
        var inputHeight: CGFloat { NectarMetrics.s(40) }
    }

    static let button = Button()

    // MARK: - Layout

    struct Layout {
        var screenHorizontal: CGFloat { NectarMetrics.spacing.lg }
        var sectionGap: CGFloat { NectarMetrics.spacing.md }
        var cardPadding: CGFloat { NectarMetrics.spacing.sm }
        var bottomSafeExtra: CGFloat { NectarMetrics.spacing.lg }
    }

    static let layout = Layout()

    // MARK: - Font sizes (pt @ design 390)

    struct FontSize {
        var largeTitle: CGFloat { NectarMetrics.s(28) }
        var title: CGFloat { NectarMetrics.s(22) }
        var headline: CGFloat { NectarMetrics.s(17) }
        var body: CGFloat { NectarMetrics.s(16) }
        var caption: CGFloat { NectarMetrics.s(13) }
        var amount: CGFloat { NectarMetrics.s(32) }
        var amountSmall: CGFloat { NectarMetrics.s(18) }
        var onboardingTitle: CGFloat { NectarMetrics.s(40) }
        var button: CGFloat { NectarMetrics.s(18) }
    }

    static let font = FontSize()
}

// MARK: - CGFloat helper

extension CGFloat {
    /// `28.scaled` → scale theo màn hình hiện tại.
    var scaled: CGFloat { NectarMetrics.s(self) }
}

extension Int {
    var scaled: CGFloat { NectarMetrics.s(CGFloat(self)) }
}

extension Double {
    var scaled: CGFloat { NectarMetrics.s(CGFloat(self)) }
}

// MARK: - View helpers

extension View {
    /// Padding ngang chuẩn màn hình.
    func screenPadding() -> some View {
        padding(.horizontal, NectarMetrics.layout.screenHorizontal)
    }

    /// Chiều cao nút primary + corner radius chuẩn (45 / 12).
    func primaryButtonStyle(background: Color = NectarColors.green) -> some View {
        self
            .font(NectarTypography.button)
            .frame(maxWidth: .infinity)
            .frame(height: NectarMetrics.button.primaryHeight)
            .foregroundStyle(.white)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: NectarMetrics.button.cornerRadius))
    }
}
