import Foundation

/// Snapshot catalog dùng chung Shop + Explore.
struct HomeCatalog: Sendable {
    var banners: [HomeBanner] = []
    var categories: [CategoryTree] = []
    var bigDeals: [ShopProduct] = []
    var recommendations: [ShopProduct] = []
    var recentlyViewed: [ShopProduct] = []
    /// `event-box` → `result.events` — Home EventBox + products.
    var eventBox: [EventBox] = []
    /// `get-active-event` — Explore banner + Home footer.
    var activeEvents: [ActiveEvent] = []
    var productReels: [ProductReel] = []
    var sellers: [Sellers] = []
}

/// Abstraction Data layer — Shop & Explore cùng inject / dùng `HomeRepository`.
@MainActor
protocol HomeCatalogProviding: AnyObject {
    func cachedCatalog() -> HomeCatalog
    func loadHomeCatalog() async -> HomeCatalog
    func prefetchLaunchBanners() async
    /// Đảm bảo đã có `activeEvents` (fetch `get-active-event` nếu cache trống).
    func ensureActiveEvents() async -> [ActiveEvent]
}
