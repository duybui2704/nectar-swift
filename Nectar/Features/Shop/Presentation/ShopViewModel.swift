import Foundation
import Combine

@MainActor
final class ShopViewModel: ObservableObject {
    @Published private(set) var isLoadingHome = false
    @Published private(set) var categories: [CategoryTree] = []
    @Published private(set) var banners: [HomeBanner] = []
    @Published private(set) var exclusiveOffers: [ShopProduct] = []
    @Published private(set) var bestSelling: [ShopProduct] = []
    @Published private(set) var recentlyViewed: [ShopProduct] = []
    @Published private(set) var eventBox: [EventBox] = []
    @Published private(set) var activeEvents: [ActiveEvent] = []
    @Published private(set) var productReels: [ProductReel] = []

    private let catalog: HomeCatalogProviding
    private var didRequestHomeLoad = false

    var currencySymbol: String {
        LocalizationStore.shared.currentCurrency?.symbol ?? "$"
    }

    init(catalog: HomeCatalogProviding = HomeRepository.shared) {
        self.catalog = catalog
    }

    func loadHome() async {
        apply(catalog.cachedCatalog())

        guard !didRequestHomeLoad else { return }
        didRequestHomeLoad = true

        isLoadingHome = true
        defer { isLoadingHome = false }

        let loaded = await catalog.loadHomeCatalog()
        apply(loaded)

        // Bảo đảm banner get-active-event (kể cả khi didLoadHome từ phiên cũ).
        if activeEvents.isEmpty {
            activeEvents = await catalog.ensureActiveEvents()
        }
    }

    private func apply(_ snapshot: HomeCatalog) {
        categories = snapshot.categories
        banners = snapshot.banners
        exclusiveOffers = snapshot.bigDeals
        bestSelling = snapshot.recommendations
        recentlyViewed = snapshot.recentlyViewed
        eventBox = snapshot.eventBox
        activeEvents = snapshot.activeEvents
        productReels = snapshot.productReels
    }
}
