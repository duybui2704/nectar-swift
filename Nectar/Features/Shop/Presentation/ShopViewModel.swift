import Foundation
import Combine

@MainActor
final class ShopViewModel: ObservableObject {
    private static var didPrefetchHome = false

    @Published private(set) var isLoadingHome = false
    @Published private(set) var locationText = LocalizationStore.shared.displayRegion
    @Published private(set) var banners: [HomeBanner] = []
    @Published private(set) var exclusiveOffers: [ShopProduct] = []
    @Published private(set) var bestSelling: [ShopProduct] = []

    var currencySymbol: String {
        LocalizationStore.shared.currentCurrency?.symbol ?? "$"
    }

    func loadHome() async {
        locationText = LocalizationStore.shared.displayRegion
        applyDisplay(
            banners: HomeCatalogStore.shared.banners,
            deals: HomeCatalogStore.shared.bigDeals,
            recommendations: HomeCatalogStore.shared.recommendations
        )

        guard !Self.didPrefetchHome else { return }

        isLoadingHome = true
        defer { isLoadingHome = false }

        let result = await AppBootstrap.prefetchHomeAPIs()

        if let geo = result.location, geo.displayText != "Unknown location" {
            locationText = geo.displayText
        } else {
            locationText = result.regionText
        }

        // Chỉ ghi API thật vào store — mock chỉ cho UI, không “fake cache”
        applyDisplay(
            banners: result.banners,
            deals: result.bigDeals,
            recommendations: result.recommendations
        )

        Self.didPrefetchHome = true
    }

    private func applyDisplay(
        banners: [HomeBanner],
        deals: [ShopProduct],
        recommendations: [ShopProduct]
    ) {
        self.banners = banners.isEmpty ? HomeMockData.banners : banners
        exclusiveOffers = deals.isEmpty ? HomeMockData.exclusiveOffers : deals
        bestSelling = recommendations.isEmpty ? HomeMockData.bestSelling : recommendations
    }
}
