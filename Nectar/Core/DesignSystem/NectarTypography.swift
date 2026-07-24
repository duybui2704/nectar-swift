import SwiftUI

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
}
