import Foundation
import SwiftUI

/// Tab shell: giữ sống mọi tab (không `.id(selectedTab)`) → tránh recreate ViewModel / re-download ảnh.
/// Điều hướng push/modal/deep link đi qua `AppRouter`.
struct MainShellView: View {
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var router: AppRouter
    @StateObject private var tabBarVisibility = TabBarVisibility()
    @HotReloadObserver private var _hr

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                tabPage(.shop) {
                    RoutedNavigationStack(path: router.path(for: .shop)) {
                        ShopView()
                    }
                }
                tabPage(.explore) {
                    RoutedNavigationStack(path: router.path(for: .explore)) {
                        ExploreView()
                    }
                }
                tabPage(.cart) {
                    RoutedNavigationStack(path: router.path(for: .cart)) {
                        CartView()
                    }
                }
                tabPage(.favourite) {
                    RoutedNavigationStack(path: router.path(for: .favourite)) {
                        FavouriteView()
                    }
                }
                tabPage(.account) {
                    RoutedNavigationStack(path: router.path(for: .account)) {
                        ProfileView()
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
        .onChange(of: router.selectedTab) { _, _ in
            tabBarVisibility.reset()
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
