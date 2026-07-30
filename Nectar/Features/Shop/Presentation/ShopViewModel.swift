import Foundation
import Combine

@MainActor
final class ShopViewModel: ObservableObject {
    private static var didPrefetchHome = false

    @Published private(set) var isLoadingHome = false
    @Published private(set) var locationText = LocalizationStore.shared.displayRegion
    @Published private(set) var categories: [CategoryTree] = []
    @Published private(set) var banners: [HomeBanner] = []
    @Published private(set) var exclusiveOffers: [ShopProduct] = []
    @Published private(set) var bestSelling: [ShopProduct] = []

    var currencySymbol: String {
        LocalizationStore.shared.currentCurrency?.symbol ?? "$"
    }

    func loadHome() async {
        locationText = LocalizationStore.shared.displayRegion
        applyDisplay(
            categories: HomeCatalogStore.shared.categories,
            banners: HomeCatalogStore.shared.banners,
            deals: HomeCatalogStore.shared.bigDeals,
            recommendations: HomeCatalogStore.shared.recommendations
        )

        guard !Self.didPrefetchHome else { return }

        isLoadingHome = true
        defer { isLoadingHome = false }

        // 1) Products / location trước
        let result = await AppBootstrap.prefetchHomeAPIs()
        print("🔍 result categories: \(result.categories)")
        if let geo = result.location, geo.displayText != "Unknown location" {
            locationText = geo.displayText
        } else {
            locationText = result.regionText
        }

        applyDisplay(
            categories: result.categories,
            banners: result.banners,
            deals: result.bigDeals,
            recommendations: result.recommendations
        )
        Self.didPrefetchHome = true
    }

    private func applyDisplay(
        categories: [CategoryTree],
        banners: [HomeBanner],
        deals: [ShopProduct],
        recommendations: [ShopProduct]
    ) {
        self.categories = categories
        self.banners = banners
        exclusiveOffers = deals
        bestSelling = recommendations
    }
}
