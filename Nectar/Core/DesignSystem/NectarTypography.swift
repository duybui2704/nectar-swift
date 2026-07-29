import SwiftUI
import UIKit
import CoreText

/// Typography scale theo `NectarMetrics` — tự co giãn trên mọi iPhone.
enum NectarTypography {
    static var largeTitle: Font {
        .system(size: NectarMetrics.font.largeTitle, weight: .bold, design: .rounded)
    }

    static var title: Font {
        .system(size: NectarMetrics.font.title, weight: .semibold, design: .rounded)
    }

    static var headline: Font {
        .system(size: NectarMetrics.font.headline, weight: .semibold)
    }

    static var body: Font {
        .system(size: NectarMetrics.font.body, weight: .regular)
    }

    static var caption: Font {
        .system(size: NectarMetrics.font.caption, weight: .regular)
    }

    static var amount: Font {
        .system(size: NectarMetrics.font.amount, weight: .bold, design: .rounded)
    }

    static var amountSmall: Font {
        .system(size: NectarMetrics.font.amountSmall, weight: .semibold, design: .rounded)
    }

    static var onboardingTitle: Font {
        .system(size: NectarMetrics.font.onboardingTitle, weight: .bold, design: .rounded)
    }

    static var button: Font {
        .system(size: NectarMetrics.font.button, weight: .semibold)
    }

    /// Brand script (Great Vibes) — dùng cho chữ “Nectar”.
    static func brandScript(size: CGFloat) -> Font {
        NectarFonts.greatVibes(size: size)
    }
}

// MARK: - Custom font registration

/// Custom fonts trong `Resources/Fonts` + `UIAppFonts` (Info.plist).
enum NectarFonts {
    /// PostScript name của Great Vibes Regular.
    static let greatVibesName = "GreatVibes-Regular"

    static func greatVibes(size: CGFloat) -> Font {
        registerIfNeeded()
        if UIFont(name: greatVibesName, size: size) != nil {
            return .custom(greatVibesName, size: size)
        }
        return .system(size: size, weight: .heavy, design: .serif).italic()
    }

    private static var didAttemptRegister = false

    private static func registerIfNeeded() {
        guard !didAttemptRegister else { return }
        didAttemptRegister = true
        guard UIFont(name: greatVibesName, size: 12) == nil else { return }
        guard let url = Bundle.main.url(forResource: "GreatVibes-Regular", withExtension: "ttf") else {
            #if DEBUG
            print("⚠️ Font: không tìm thấy GreatVibes-Regular.ttf trong bundle")
            #endif
            return
        }
        var error: Unmanaged<CFError>?
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
        #if DEBUG
        if let error {
            print("⚠️ Font register failed:", error.takeUnretainedValue())
        } else {
            print("✅ Font registered:", greatVibesName)
        }
        #endif
    }
}
