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
    /// Products tab đầu của event box — parse sẵn, không decode trong View khi scroll.
    @Published private(set) var eventBoxProducts: [ShopProduct] = []
    @Published private(set) var activeEvents: [ActiveEvent] = []
    @Published private(set) var productReels: [ProductReel] = []
    @Published private(set) var sellers: [Sellers] = []

    private let catalog: HomeCatalogProviding
    private var didRequestHomeLoad = false

    var currencySymbol: String {
        LocalizationStore.shared.currentCurrency?.symbol ?? "$"
    }

    var primaryEvent: EventBox? { eventBox.first }

    // MARK: - Per-section skeleton flags (load + chưa có data)

    var showCategoriesSkeleton: Bool { isLoadingHome && categories.isEmpty }
    var showBannersSkeleton: Bool { isLoadingHome && banners.isEmpty }
    var showReelsSkeleton: Bool { isLoadingHome && productReels.isEmpty }
    var showRecentlyViewedSkeleton: Bool { isLoadingHome && recentlyViewed.isEmpty }
    var showExclusiveSkeleton: Bool { isLoadingHome && exclusiveOffers.isEmpty }
    var showBestSellingSkeleton: Bool { isLoadingHome && bestSelling.isEmpty }
    var showSellersSkeleton: Bool { isLoadingHome && sellers.isEmpty }
    var showEventBoxSkeleton: Bool { isLoadingHome && eventBox.isEmpty }

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
        eventBoxProducts = snapshot.eventBox.first.map {
            HomeDTOMapper.eventPageProducts(from: $0.pageData)
        } ?? []
        activeEvents = snapshot.activeEvents
        productReels = snapshot.productReels
        sellers = snapshot.sellers
    }
}
