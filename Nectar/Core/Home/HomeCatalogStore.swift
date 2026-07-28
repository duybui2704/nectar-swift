import Foundation
import Combine

/// Cache catalog Home (banners + rails) — launch + shop prefetch ghi vào đây.
@MainActor
final class HomeCatalogStore: ObservableObject {
    static let shared = HomeCatalogStore()

    @Published private(set) var banners: [HomeBanner] = []
    @Published private(set) var recommendations: [ShopProduct] = []
    @Published private(set) var bigDeals: [ShopProduct] = []

    func setBanners(_ items: [HomeBanner]) {
        guard !items.isEmpty else { return }
        banners = items
    }

    func setRecommendations(_ items: [ShopProduct]) {
        guard !items.isEmpty else { return }
        recommendations = items
    }

    func setBigDeals(_ items: [ShopProduct]) {
        guard !items.isEmpty else { return }
        bigDeals = items
    }
}
