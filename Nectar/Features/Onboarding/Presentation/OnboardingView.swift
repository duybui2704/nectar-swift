import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var session: AppSession
    @State private var page = 0
    @HotReloadObserver private var _hr

    private var pages: [(title: String, body: String, image: String)] = [
        ("Welcome\n to our store", "Ger your groceries in as fast as one hours", "img_onboarding"),
    ]

    var body: some View {
        ZStack {
         
                ForEach(pages.indices, id: \.self) { index in
                    ZStack {
                        Image(pages[index].image)
                            .resizable()
                            .scaledToFill()
                            .ignoresSafeArea()

                        // Soft fade so title/body stay readable over the photo
                        LinearGradient(
                            colors: [
                                .black.opacity(0.05),
                                .black.opacity(0.45),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .ignoresSafeArea()

                        VStack(spacing: NectarMetrics.spacing.md) {
                            Spacer()

                            Text(pages[index].title)
                                .font(NectarTypography.onboardingTitle)
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                                .screenPadding()

                            Text(pages[index].body)
                                .font(NectarTypography.body)
                                .foregroundStyle(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .screenPadding()

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
                            .padding(.bottom, NectarMetrics.layout.bottomSafeExtra +  NectarMetrics.spacing.md)
                            
                        }
                    }
                    .tag(index)
                }
            }
         
            .ignoresSafeArea()
        .hotReload()
    }
}
