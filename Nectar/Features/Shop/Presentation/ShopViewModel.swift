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
    @Published private(set) var recentlyViewed: [ShopProduct] = []
    @Published private(set) var eventBox: [EventBox] = []

    var currencySymbol: String {
        LocalizationStore.shared.currentCurrency?.symbol ?? "$"
    }

    func loadHome() async {
        locationText = LocalizationStore.shared.displayRegion
        applyDisplay(
            categories: HomeCatalogStore.shared.categories,
            banners: HomeCatalogStore.shared.banners,
            deals: HomeCatalogStore.shared.bigDeals,
            recommendations: HomeCatalogStore.shared.recommendations,
            recentlyViewed: HomeCatalogStore.shared.recentlyViewed,
            eventBox: HomeCatalogStore.shared.eventBox
        )

        guard !Self.didPrefetchHome else { return }

        isLoadingHome = true
        defer { isLoadingHome = false }

        let result = await AppBootstrap.prefetchHomeAPIs()
        print("result ====", result.eventBox)

        applyDisplay(
            categories: result.categories,
            banners: result.banners,
            deals: result.bigDeals,
            recommendations: result.recommendations,
            recentlyViewed: result.recentlyViewed,
            eventBox: HomeCatalogStore.shared.eventBox
        )
        Self.didPrefetchHome = true
    }

    private func applyDisplay(
        categories: [CategoryTree],
        banners: [HomeBanner],
        deals: [ShopProduct],
        recommendations: [ShopProduct],
        recentlyViewed: [ShopProduct],
        eventBox: [EventBox]
    ) {
        self.categories = categories
        self.banners = banners
        exclusiveOffers = deals
        bestSelling = recommendations
        self.recentlyViewed = recentlyViewed
        self.eventBox = eventBox
    }
}
