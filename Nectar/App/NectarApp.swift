import SwiftUI

@main
struct NectarApp: App {
    @StateObject private var session: AppSession = .init()

    init() {
        HotReloadBootstrap.configure()
        ImageCacheBootstrap.configure()
        _ = NectarTypography.brandScript(size: 12) // pre-register Great Vibes
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .preferredColorScheme(.light)
        }
    }
}
