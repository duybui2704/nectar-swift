import Foundation
import SwiftUI

/// Tab shell: giữ sống tab đã mở (không `.id(selectedTab)`).
/// Lazy-mount tab chưa từng chọn → tránh Explore/Cart… cạnh tranh CPU/network với Home lần đầu.
/// Điều hướng push/modal/deep link đi qua `AppRouter`.
struct MainShellView: View {
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var router: AppRouter
    @StateObject private var tabBarVisibility = TabBarVisibility()
    /// Chỉ mount tab đã từng chọn — Home (shop) luôn có vì là tab mặc định.
    @State private var mountedTabs: Set<MainTab> = [.shop]
    @HotReloadObserver private var _hr

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                tabPage(.shop) {
                    RoutedNavigationStack(path: router.path(for: .shop)) {
                        ShopView()
                    }
                }
                if mountedTabs.contains(.explore) {
                    tabPage(.explore) {
                        RoutedNavigationStack(path: router.path(for: .explore)) {
                            ExploreView()
                        }
                    }
                }
                if mountedTabs.contains(.cart) {
                    tabPage(.cart) {
                        RoutedNavigationStack(path: router.path(for: .cart)) {
                            CartView()
                        }
                    }
                }
                if mountedTabs.contains(.favourite) {
                    tabPage(.favourite) {
                        RoutedNavigationStack(path: router.path(for: .favourite)) {
                            FavouriteView()
                        }
                    }
                }
                if mountedTabs.contains(.account) {
                    tabPage(.account) {
                        RoutedNavigationStack(path: router.path(for: .account)) {
                            ProfileView()
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            FloatingTabBar(
                selection: Binding(
                    get: { router.selectedTab },
                    set: { router.selectTab($0) }
                )
            )
        }
        .environmentObject(tabBarVisibility)
        .ignoresSafeArea(.keyboard)
        .onChange(of: router.selectedTab) { _, tab in
            mountedTabs.insert(tab)
            syncTabBarForNavigation()
        }
        .onChange(of: router.shopPath.count) { _, _ in syncTabBarForNavigation() }
        .onChange(of: router.explorePath.count) { _, _ in syncTabBarForNavigation() }
        .onChange(of: router.cartPath.count) { _, _ in syncTabBarForNavigation() }
        .onChange(of: router.favouritePath.count) { _, _ in syncTabBarForNavigation() }
        .onChange(of: router.accountPath.count) { _, _ in syncTabBarForNavigation() }
        .onAppear {
            mountedTabs.insert(router.selectedTab)
            syncTabBarForNavigation()
        }
        .sheet(item: $router.presentedSheet) { sheet in
            AppSheetView(sheet: sheet)
        }
        .fullScreenCover(item: $router.presentedFullScreen) { cover in
            fullScreenContent(cover)
        }
        .onOpenURL { url in
            _ = router.handleDeepLink(url)
        }
        .hotReload()
    }

    private func syncTabBarForNavigation() {
        let hasPush: Bool
        switch router.selectedTab {
        case .shop: hasPush = !router.shopPath.isEmpty
        case .explore: hasPush = !router.explorePath.isEmpty
        case .cart: hasPush = !router.cartPath.isEmpty
        case .favourite: hasPush = !router.favouritePath.isEmpty
        case .account: hasPush = !router.accountPath.isEmpty
        }
        tabBarVisibility.setNavigationHidden(hasPush)
    }

    @ViewBuilder
    private func tabPage<Content: View>(_ tab: MainTab, @ViewBuilder content: () -> Content) -> some View {
        content()
            .opacity(router.selectedTab == tab ? 1 : 0)
            .allowsHitTesting(router.selectedTab == tab)
            .accessibilityHidden(router.selectedTab != tab)
    }

    @ViewBuilder
    private func fullScreenContent(_ cover: AppFullScreen) -> some View {
        switch cover {
        case .productReel(let initialID):
            // Payload video nằm ở ShopViewModel — cover generic; rail vẫn present local khi có list.
            PlaceholderFeatureView(
                title: "Reel #\(initialID)",
                message: "Full-screen reel via AppRouter — dùng ProductReelsRail.fullScreenCover khi có data."
            )
        }
    }
}
