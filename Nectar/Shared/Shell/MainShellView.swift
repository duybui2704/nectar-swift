import Foundation
import SwiftUI

enum DeepLinkRouter {
    enum Destination: Equatable {
        case cart
        case explore
        case favourite
    }

    @MainActor
    static func handle(url: URL, session: AppSession) -> Destination? {
        guard url.scheme == "nectar" else { return nil }
        guard session.route == .main else { return nil }
        switch url.host {
        case "cart": return .cart
        case "explore": return .explore
        case "favourite", "favorite": return .favourite
        default: return nil
        }
    }
}

enum MainTab: Int, Hashable, CaseIterable {
    case shop = 0
    case explore = 1
    case cart = 2
    case favourite = 3
    case account = 4
}

/// Tab shell: giữ sống mọi tab (không `.id(selectedTab)`) → tránh recreate ViewModel / re-download ảnh.
struct MainShellView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var tabBarVisibility = TabBarVisibility()
    @State private var selectedTab: MainTab = .shop
    @HotReloadObserver private var _hr

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                tabPage(.shop) { ShopView() }
                tabPage(.explore) { ExploreView() }
                tabPage(.cart) { CartView() }
                tabPage(.favourite) { FavouriteView() }
                tabPage(.account) { ProfileView() }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            FloatingTabBar(selection: $selectedTab)
        }
        .environmentObject(tabBarVisibility)
        .ignoresSafeArea(.keyboard)
        .onChange(of: selectedTab) { _, _ in
            tabBarVisibility.reset()
        }
        .onOpenURL { url in
            applyDeepLink(DeepLinkRouter.handle(url: url, session: session))
        }
        .hotReload()
    }

    @ViewBuilder
    private func tabPage<Content: View>(_ tab: MainTab, @ViewBuilder content: () -> Content) -> some View {
        content()
            .opacity(selectedTab == tab ? 1 : 0)
            .allowsHitTesting(selectedTab == tab)
            // Giữ trong hierarchy nhưng không nhận hit khi ẩn
            .accessibilityHidden(selectedTab != tab)
    }

    private func applyDeepLink(_ destination: DeepLinkRouter.Destination?) {
        guard let destination else { return }
        switch destination {
        case .cart: selectedTab = .cart
        case .explore: selectedTab = .explore
        case .favourite: selectedTab = .favourite
        }
    }
}
