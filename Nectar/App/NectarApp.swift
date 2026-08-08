import SwiftUI

@main
struct NectarApp: App {
    @StateObject private var session: AppSession = .init()
    @StateObject private var router: AppRouter = .init()

    init() {
        HotReloadBootstrap.configure()
        ImageCacheBootstrap.configure()
        NectarFonts.configureGlobalAppearance()
        DebugToolsBootstrap.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .environmentObject(router)
                .preferredColorScheme(.light)
                .nectarGlobalFont()
        }
    }
}
