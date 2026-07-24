import SwiftUI

@main
struct NectarApp: App {
    @StateObject private var session: AppSession = .init()

    init() {
        HotReloadBootstrap.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .preferredColorScheme(.light)
        }
    }
}
