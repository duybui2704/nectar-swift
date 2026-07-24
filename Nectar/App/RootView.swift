import SwiftUI

struct RootView: View {
    @EnvironmentObject private var session: AppSession
    @HotReloadObserver private var _hr

    var body: some View {
        Group {
            switch session.route {
            case .splash:
                SplashView()
            case .onboarding:
                OnboardingView()
            case .login:
                LoginView()
            case .main:
                OnboardingView()
            }
        }
        .animation(.easeInOut(duration: 0.28), value: session.route)
        .task {
            if session.route == .splash {
                await session.bootstrap()
            }
        }
        .hotReload()
    }
}
