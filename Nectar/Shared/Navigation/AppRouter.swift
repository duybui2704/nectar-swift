import Foundation
import SwiftUI

/// Bộ điều hướng dùng chung toàn app (sau khi vào `.main`).
///
/// - Tab: `selectedTab`
/// - Push/pop: path theo từng tab (`shopPath`, …)
/// - Modal: `presentedSheet` / `presentedFullScreen`
///
/// Inject qua `.environmentObject(router)`. Gọi từ bất kỳ View nào:
/// ```swift
/// @EnvironmentObject private var router: AppRouter
/// router.push(.productDetail(id: "12"))
/// router.open(.orders, tab: .account)
/// router.selectTab(.cart)
/// ```
@MainActor
final class AppRouter: ObservableObject {
    @Published var selectedTab: MainTab = .shop

    @Published var shopPath: [AppDestination] = []
    @Published var explorePath: [AppDestination] = []
    @Published var cartPath: [AppDestination] = []
    @Published var favouritePath: [AppDestination] = []
    @Published var accountPath: [AppDestination] = []

    @Published var presentedSheet: AppSheet?
    @Published var presentedFullScreen: AppFullScreen?

    // MARK: - Tab

    /// Chọn tab. Tap lại tab đang active → pop về root (UX chuẩn).
    func selectTab(_ tab: MainTab) {
        if selectedTab == tab {
            popToRoot(tab: tab)
        } else {
            selectedTab = tab
        }
    }

    /// Reset sau logout / rời main shell.
    func reset() {
        selectedTab = .shop
        popToRootAllTabs()
        dismissAllModals()
    }

    // MARK: - Stack

    /// Push lên stack của tab hiện tại (hoặc `tab` chỉ định).
    func push(_ destination: AppDestination, tab: MainTab? = nil) {
        let target = tab ?? selectedTab
        if let tab, tab != selectedTab {
            selectedTab = tab
        }
        append(destination, to: target)
    }

    /// Đổi tab rồi push (deep link / CTA từ tab khác).
    func open(_ destination: AppDestination, tab: MainTab) {
        selectedTab = tab
        append(destination, to: tab)
    }

    /// Thay toàn bộ stack tab bằng một destination (deep link “mở đúng màn”).
    func replace(stack destination: AppDestination, tab: MainTab) {
        selectedTab = tab
        setPath([destination], for: tab)
    }

    func pop(tab: MainTab? = nil) {
        let target = tab ?? selectedTab
        var current = currentPath(for: target)
        guard !current.isEmpty else { return }
        current.removeLast()
        setPath(current, for: target)
    }

    func popToRoot(tab: MainTab? = nil) {
        setPath([], for: tab ?? selectedTab)
    }

    func popToRootAllTabs() {
        shopPath = []
        explorePath = []
        cartPath = []
        favouritePath = []
        accountPath = []
    }

    // MARK: - Presentation

    func present(_ sheet: AppSheet) {
        presentedSheet = sheet
    }

    func presentFullScreen(_ cover: AppFullScreen) {
        presentedFullScreen = cover
    }

    func dismissSheet() {
        presentedSheet = nil
    }

    func dismissFullScreen() {
        presentedFullScreen = nil
    }

    func dismissAllModals() {
        presentedSheet = nil
        presentedFullScreen = nil
    }

    // MARK: - Deep link

    @discardableResult
    func handleDeepLink(_ url: URL) -> Bool {
        guard let route = DeepLinkRouter.parse(url) else { return false }
        apply(route)
        return true
    }

    func apply(_ route: DeepLinkRouter.Route) {
        dismissAllModals()
        switch route {
        case .tab(let tab):
            selectedTab = tab
            popToRoot(tab: tab)
        case .destination(let tab, let destination, let replace):
            if replace {
                self.replace(stack: destination, tab: tab)
            } else {
                open(destination, tab: tab)
            }
        }
    }

    // MARK: - Path binding

    func path(for tab: MainTab) -> Binding<[AppDestination]> {
        Binding(
            get: { self.currentPath(for: tab) },
            set: { self.setPath($0, for: tab) }
        )
    }

    // MARK: - Private

    private func currentPath(for tab: MainTab) -> [AppDestination] {
        switch tab {
        case .shop: return shopPath
        case .explore: return explorePath
        case .cart: return cartPath
        case .favourite: return favouritePath
        case .account: return accountPath
        }
    }

    private func setPath(_ path: [AppDestination], for tab: MainTab) {
        switch tab {
        case .shop: shopPath = path
        case .explore: explorePath = path
        case .cart: cartPath = path
        case .favourite: favouritePath = path
        case .account: accountPath = path
        }
    }

    private func append(_ destination: AppDestination, to tab: MainTab) {
        setPath(currentPath(for: tab) + [destination], for: tab)
    }
}
