import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var session: AppSession
    @State private var page = 0
    @HotReloadObserver private var _hr

    private var pages: [(title: String, body: String, image: String)] = [
        ("Welcome\n to our store", "Ger your groceries in as fast as one hour", "img_onboarding"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    VStack(spacing: BankMetrics.spacing.md) {
                        Spacer(minLength: BankMetrics.spacing.xl)

                        Image(pages[index].image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: BankMetrics.icon.onboardingWidth)

                        Text(pages[index].title)
                            .font(BankTypography.onboardingTitle)
                            .foregroundStyle(BankColors.textPrimary)
                            .multilineTextAlignment(.center)
                            .screenPadding()

                        Text(pages[index].body)
                            .font(BankTypography.body)
                            .foregroundStyle(BankColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .screenPadding()

                        Spacer(minLength: BankMetrics.spacing.lg)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button {
                session.completeOnboarding()
            } label: {
                Text("Get Started")
                    .font(BankTypography.button)
                    .frame(maxWidth: .infinity)
                    .frame(height: BankMetrics.button.onboardingHeight)
                    .foregroundStyle(.white)
                    .background(BankColors.green)
                    .clipShape(RoundedRectangle(cornerRadius: BankMetrics.radius.xl))
            }
            .screenPadding()
            .padding(.bottom, BankMetrics.layout.bottomSafeExtra)
        }
        .hotReload()
    }
}
