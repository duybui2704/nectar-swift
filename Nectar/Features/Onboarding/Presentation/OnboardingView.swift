import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var session: AppSession
    @State private var page = 0
    @HotReloadObserver private var _hr

    private var pages: [(title: String, body: String, image: String)] = [
        ("Welcome\n to our store", "Ger your groceries in as fast as one hours", "img_onboarding"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    VStack(spacing: NectarMetrics.spacing.md) {
                        Spacer(minLength: NectarMetrics.spacing.xl)

                        Image(pages[index].image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: NectarMetrics.icon.onboardingWidth, height: NectarMetrics.icon.onboardingWidth)
                            .padding(.horizontal, NectarMetrics.spacing.lg)

                        Text(pages[index].title)
                            .font(NectarTypography.onboardingTitle)
                            .foregroundStyle(NectarColors.textPrimary)
                            .multilineTextAlignment(.center)
                            .screenPadding()

                        Text(pages[index].body)
                            .font(NectarTypography.body)
                            .foregroundStyle(NectarColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .screenPadding()

                        Spacer(minLength: NectarMetrics.spacing.lg)
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Button {
                session.completeOnboarding()
            } label: {
                Text("Get Started")
                    .font(NectarTypography.button)
                    .frame(maxWidth: .infinity)
                    .frame(height: NectarMetrics.button.onboardingHeight)
                    .foregroundStyle(.white)
                    .background(NectarColors.green)
                    .clipShape(RoundedRectangle(cornerRadius: NectarMetrics.radius.xl))
            }
            .screenPadding()
            .padding(.bottom, NectarMetrics.layout.bottomSafeExtra)
        }
        .hotReload()
    }
}
