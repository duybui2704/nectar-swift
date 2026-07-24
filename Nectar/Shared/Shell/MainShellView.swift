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

enum MainTab: Int, Hashable {
    case shop = 0
    case explore = 1
    case cart = 2
    case favourite = 3
    case account = 4
}

/// Tab shell with deep-link routing support.
struct MainShellView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var lockService = SessionLockService.shared
    @State private var selectedTab: MainTab = .shop
    @HotReloadObserver private var _hr

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                ShopView()
                    .tag(MainTab.shop)
                    .tabItem { Label("Shop", systemImage: "storefront") }

                ExploreView()
                    .tag(MainTab.explore)
                    .tabItem { Label("Explore", systemImage: "line.3.horizontal.decrease.circle") }

                CartView()
                    .tag(MainTab.cart)
                    .tabItem { Label("Cart", systemImage: "cart") }

                FavouriteView()
                    .tag(MainTab.favourite)
                    .tabItem { Label("Favourite", systemImage: "heart") }

                ProfileView()
                    .tag(MainTab.account)
                    .tabItem { Label("Account", systemImage: "person") }
            }
            .tint(NectarColors.green)
            .onAppear(perform: configureTabBarAppearance)
            .onOpenURL { url in
                applyDeepLink(DeepLinkRouter.handle(url: url, session: session))
            }
        }
        .hotReload()
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.08)

        let normal = appearance.stackedLayoutAppearance.normal
        normal.iconColor = UIColor(NectarColors.textPrimary)
        normal.titleTextAttributes = [
            .foregroundColor: UIColor(NectarColors.textPrimary),
        ]

        let selected = appearance.stackedLayoutAppearance.selected
        selected.iconColor = UIColor(NectarColors.green)
        selected.titleTextAttributes = [
            .foregroundColor: UIColor(NectarColors.green),
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
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
