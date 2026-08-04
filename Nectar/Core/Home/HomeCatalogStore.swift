import Foundation
import Combine

/// Cache catalog Home (banners + rails) — launch + shop prefetch ghi vào đây.
@MainActor
final class HomeCatalogStore: ObservableObject {
    static let shared = HomeCatalogStore()

    @Published private(set) var banners: [HomeBanner] = []
    @Published private(set) var categories: [CategoryTree] = []
    @Published private(set) var recommendations: [ShopProduct] = []
    @Published private(set) var bigDeals: [ShopProduct] = []
    @Published private(set) var recentlyViewed: [ShopProduct] = []
    @Published private(set) var eventBox: [EventBox] = []

    func setBanners(_ items: [HomeBanner]) {
        guard !items.isEmpty else { return }
        banners = items
    }

    func setCategories(_ items: [CategoryTree]) {
        guard !items.isEmpty else { return }
        categories = items
    }

    func setRecommendations(_ items: [ShopProduct]) {
        guard !items.isEmpty else { return }
        recommendations = items
    }

    func setBigDeals(_ items: [ShopProduct]) {
        guard !items.isEmpty else { return }
        bigDeals = items
    }

    func setRecentlyViewed(_ items: [ShopProduct]) {
        guard !items.isEmpty else { return }
        recentlyViewed = items
    }
    
    func setEventBox(_ items: [EventBox]) {
        guard !items.isEmpty else { return }
        eventBox = items
    }
}
