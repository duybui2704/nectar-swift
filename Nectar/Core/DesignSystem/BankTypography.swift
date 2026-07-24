import SwiftUI

/// Typography scale theo `BankMetrics` — tự co giãn trên mọi iPhone.
enum BankTypography {
    static var largeTitle: Font {
        .system(size: BankMetrics.font.largeTitle, weight: .bold, design: .rounded)
    }

    static var title: Font {
        .system(size: BankMetrics.font.title, weight: .semibold, design: .rounded)
    }

    static var headline: Font {
        .system(size: BankMetrics.font.headline, weight: .semibold)
    }

    static var body: Font {
        .system(size: BankMetrics.font.body, weight: .regular)
    }

    static var caption: Font {
        .system(size: BankMetrics.font.caption, weight: .regular)
    }

    static var amount: Font {
        .system(size: BankMetrics.font.amount, weight: .bold, design: .rounded)
    }

    static var amountSmall: Font {
        .system(size: BankMetrics.font.amountSmall, weight: .semibold, design: .rounded)
    }

    static var onboardingTitle: Font {
        .system(size: BankMetrics.font.onboardingTitle, weight: .bold, design: .rounded)
    }

    static var button: Font {
        .system(size: BankMetrics.font.button, weight: .semibold)
    }
}
