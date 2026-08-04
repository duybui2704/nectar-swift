import Foundation

/// Snapshot catalog Home — Domain không biết Store/API.
struct HomeCatalog: Sendable {
    var banners: [HomeBanner] = []
    var categories: [CategoryTree] = []
    var bigDeals: [ShopProduct] = []
    var recommendations: [ShopProduct] = []
    var recentlyViewed: [ShopProduct] = []
    var eventBox: [EventBox] = []
    var productReels: [ProductReel] = []
}

/// Abstraction Data layer cho Shop ViewModel (testable / inject được).
@MainActor
protocol HomeCatalogProviding: AnyObject {
    func cachedCatalog() -> HomeCatalog
    func loadHomeCatalog() async -> HomeCatalog
    func prefetchLaunchBanners() async
}
