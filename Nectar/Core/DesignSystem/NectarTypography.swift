import SwiftUI
import UIKit
import CoreText

// MARK: - Typography scale (Elms Sans toàn app)

/// Typography scale theo `NectarMetrics` — font mặc định **Elms Sans**.
enum NectarTypography {
    static var largeTitle: Font {
        NectarFonts.elmsSans(size: NectarMetrics.font.largeTitle, weight: .bold)
    }

    static var title: Font {
        NectarFonts.elmsSans(size: NectarMetrics.font.title, weight: .semibold)
    }

    static var headline: Font {
        NectarFonts.elmsSans(size: NectarMetrics.font.headline, weight: .semibold)
    }

    static var body: Font {
        NectarFonts.elmsSans(size: NectarMetrics.font.body, weight: .regular)
    }

    static var caption: Font {
        NectarFonts.elmsSans(size: NectarMetrics.font.caption, weight: .regular)
    }

    static var amount: Font {
        NectarFonts.elmsSans(size: NectarMetrics.font.amount, weight: .bold)
    }

    static var amountSmall: Font {
        NectarFonts.elmsSans(size: NectarMetrics.font.amountSmall, weight: .semibold)
    }

    static var onboardingTitle: Font {
        NectarFonts.elmsSans(size: NectarMetrics.font.onboardingTitle, weight: .bold)
    }

    static var button: Font {
        NectarFonts.elmsSans(size: NectarMetrics.font.button, weight: .semibold)
    }

    /// Logo script — **chỉ** header “Nectar Market” (Great Vibes), không dùng global.
    static func brandScript(size: CGFloat) -> Font {
        NectarFonts.greatVibes(size: size)
    }
}

// MARK: - Font registry

enum NectarFonts {
    enum ElmsSansName {
        static let regular = "ElmsSans-Regular"
        static let medium = "ElmsSans-Medium"
        static let semiBold = "ElmsSans-SemiBold"
        static let bold = "ElmsSans-Bold"
    }

    private static let bundledFonts: [(resource: String, postScript: String)] = [
        ("GreatVibes-Regular", "GreatVibes-Regular"),
        ("ElmsSans-Regular", ElmsSansName.regular),
        ("ElmsSans-Medium", ElmsSansName.medium),
        ("ElmsSans-SemiBold", ElmsSansName.semiBold),
        ("ElmsSans-Bold", ElmsSansName.bold),
    ]

    /// Elms Sans — font UI mặc định toàn app.
    static func elmsSans(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        registerIfNeeded()
        let name = postScriptName(for: weight)
        if UIFont(name: name, size: size) != nil {
            return .custom(name, size: size)
        }
        return .system(size: size, weight: weight)
    }

    /// Great Vibes — logo “Nectar Market” only.
    static func greatVibes(size: CGFloat) -> Font {
        registerIfNeeded()
        if UIFont(name: "GreatVibes-Regular", size: size) != nil {
            return .custom("GreatVibes-Regular", size: size)
        }
        return .system(size: size, weight: .heavy, design: .serif).italic()
    }

    /// Gọi 1 lần lúc launch: đăng ký font + UIKit appearance.
    static func configureGlobalAppearance() {
        registerIfNeeded()
        applyUIKitAppearance()
    }

    // MARK: - Private

    private static var didAttemptRegister = false

    private static func postScriptName(for weight: Font.Weight) -> String {
        switch weight {
        case .bold, .heavy, .black:
            return ElmsSansName.bold
        case .semibold:
            return ElmsSansName.semiBold
        case .medium:
            return ElmsSansName.medium
        default:
            return ElmsSansName.regular
        }
    }

    private static func registerIfNeeded() {
        guard !didAttemptRegister else { return }
        didAttemptRegister = true

        for item in bundledFonts {
            guard UIFont(name: item.postScript, size: 12) == nil else { continue }
            guard let url = Bundle.main.url(forResource: item.resource, withExtension: "ttf") else {
                NectarLog.log("⚠️ Font missing in bundle: \(item.resource).ttf", title: "Font")
                continue
            }
            var error: Unmanaged<CFError>?
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
            if let error {
                NectarLog.log(
                    "⚠️ Font register failed \(item.resource): \(error.takeUnretainedValue())",
                    title: "Font"
                )
            }
        }
    }

    private static func applyUIKitAppearance() {
        let regular = uiFont(size: NectarMetrics.font.body, weight: .regular)
        let headline = uiFont(size: NectarMetrics.font.headline, weight: .semibold)

        UILabel.appearance().font = regular
        UITextField.appearance().font = regular
        UITextView.appearance().font = regular

        UINavigationBar.appearance().titleTextAttributes = [
            .font: headline,
        ]
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .font: uiFont(size: NectarMetrics.font.largeTitle, weight: .bold),
        ]
    }

    private static func uiFont(size: CGFloat, weight: Font.Weight) -> UIFont {
        let name = postScriptName(for: weight)
        return UIFont(name: name, size: size) ?? .systemFont(ofSize: size, weight: uiKitWeight(weight))
    }

    private static func uiKitWeight(_ weight: Font.Weight) -> UIFont.Weight {
        switch weight {
        case .bold, .heavy, .black: return .bold
        case .semibold: return .semibold
        case .medium: return .medium
        case .light: return .light
        case .thin, .ultraLight: return .thin
        default: return .regular
        }
    }
}

// MARK: - SwiftUI global font

private struct NectarGlobalFontModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(NectarTypography.body)
            .environment(\.font, NectarTypography.body)
    }
}

extension View {
    /// Áp Elms Sans làm font mặc định cho subtree SwiftUI (Text không ghi đè `.font`).
    func nectarGlobalFont() -> some View {
        modifier(NectarGlobalFontModifier())
    }
}
