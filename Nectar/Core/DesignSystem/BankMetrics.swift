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
/// .padding(BankMetrics.spacing.lg)
/// .font(BankTypography.title)
/// .frame(height: BankMetrics.button.primaryHeight)
/// Text("Hi").font(.system(size: 28.scaled))
/// ```
enum BankMetrics {

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
        var xxxs: CGFloat { BankMetrics.s(4) }
        var xxs: CGFloat { BankMetrics.s(8) }
        var xs: CGFloat { BankMetrics.s(12) }
        var sm: CGFloat { BankMetrics.s(16) }
        var md: CGFloat { BankMetrics.s(20) }
        var lg: CGFloat { BankMetrics.s(24) }
        var xl: CGFloat { BankMetrics.s(32) }
        var xxl: CGFloat { BankMetrics.s(40) }
        var xxxl: CGFloat { BankMetrics.s(48) }
    }

    static let spacing = Spacing()

    // MARK: - Corner radius

    struct Radius {
        var sm: CGFloat { BankMetrics.s(8) }
        var md: CGFloat { BankMetrics.s(12) }
        var lg: CGFloat { BankMetrics.s(16) }
        var xl: CGFloat { BankMetrics.s(22) }
        var pill: CGFloat { 999 }
    }

    static let radius = Radius()

    // MARK: - Icon / Illustration

    struct Icon {
        var sm: CGFloat { BankMetrics.s(20) }
        var md: CGFloat { BankMetrics.s(24) }
        var lg: CGFloat { BankMetrics.s(32) }
        var xl: CGFloat { BankMetrics.s(48) }
        var hero: CGFloat { BankMetrics.s(64) }
        /// Chiều rộng illustration onboarding (~70% màn hình, cap hợp lý).
        var onboardingWidth: CGFloat {
            min(UIScreen.main.bounds.width * 0.72, BankMetrics.s(280))
        }
    }

    static let icon = Icon()

    // MARK: - Button

    struct Button {
        var primaryHeight: CGFloat { BankMetrics.s(56) }
        /// Design Onboarding dùng 67 — giữ đúng tỷ lệ.
        var onboardingHeight: CGFloat { BankMetrics.s(67) }
        var secondaryHeight: CGFloat { BankMetrics.s(48) }
        var horizontalPadding: CGFloat { BankMetrics.spacing.lg }
    }

    static let button = Button()

    // MARK: - Layout

    struct Layout {
        var screenHorizontal: CGFloat { BankMetrics.spacing.lg }
        var sectionGap: CGFloat { BankMetrics.spacing.md }
        var cardPadding: CGFloat { BankMetrics.spacing.sm }
        var bottomSafeExtra: CGFloat { BankMetrics.spacing.lg }
    }

    static let layout = Layout()

    // MARK: - Font sizes (pt @ design 390)

    struct FontSize {
        var largeTitle: CGFloat { BankMetrics.s(28) }
        var title: CGFloat { BankMetrics.s(22) }
        var headline: CGFloat { BankMetrics.s(17) }
        var body: CGFloat { BankMetrics.s(16) }
        var caption: CGFloat { BankMetrics.s(13) }
        var amount: CGFloat { BankMetrics.s(32) }
        var amountSmall: CGFloat { BankMetrics.s(18) }
        var onboardingTitle: CGFloat { BankMetrics.s(40) }
        var button: CGFloat { BankMetrics.s(18) }
    }

    static let font = FontSize()
}

// MARK: - CGFloat helper

extension CGFloat {
    /// `28.scaled` → scale theo màn hình hiện tại.
    var scaled: CGFloat { BankMetrics.s(self) }
}

extension Int {
    var scaled: CGFloat { BankMetrics.s(CGFloat(self)) }
}

extension Double {
    var scaled: CGFloat { BankMetrics.s(CGFloat(self)) }
}

// MARK: - View helpers

extension View {
    /// Padding ngang chuẩn màn hình.
    func screenPadding() -> some View {
        padding(.horizontal, BankMetrics.layout.screenHorizontal)
    }

    /// Chiều cao nút primary + corner radius chuẩn.
    func primaryButtonStyle(background: Color = BankColors.green) -> some View {
        self
            .font(BankTypography.button)
            .frame(maxWidth: .infinity)
            .frame(height: BankMetrics.button.primaryHeight)
            .foregroundStyle(.white)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: BankMetrics.radius.xl))
    }
}
