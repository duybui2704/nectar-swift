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
    private let store: HomeCatalogStore
    private var didRequestHomeLoad = false
    private var cancellables = Set<AnyCancellable>()

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

    init(
        catalog: HomeCatalogProviding? = nil,
        store: HomeCatalogStore? = nil
    ) {
        self.catalog = catalog ?? HomeRepository.shared
        self.store = store ?? .shared
        apply(self.store.snapshot())
        bindStoreForProgressiveUpdates()
    }

    func loadHome() async {
        guard !didRequestHomeLoad else { return }
        didRequestHomeLoad = true

        isLoadingHome = true
        defer { isLoadingHome = false }

        _ = await catalog.loadHomeCatalog()

        if activeEvents.isEmpty {
            _ = await catalog.ensureActiveEvents()
        }
    }

    // MARK: - Progressive bind

    /// Helper dùng chung cho các field bind 1-1 trực tiếp từ store sang ViewModel.
    private func bind<Value>(
        _ publisher: Published<Value>.Publisher,
        to keyPath: ReferenceWritableKeyPath<ShopViewModel, Value>
    ) {
        publisher
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] value in
                self?[keyPath: keyPath] = value
            }
            .store(in: &cancellables)
    }

    /// Mỗi field store đổi → UI Home cập nhật section đó (không đợi cả catalog).
    private func bindStoreForProgressiveUpdates() {
        bind(store.$banners, to: \.banners)
        bind(store.$categories, to: \.categories)
        bind(store.$bigDeals, to: \.exclusiveOffers)
        bind(store.$recommendations, to: \.bestSelling)
        bind(store.$recentlyViewed, to: \.recentlyViewed)
        bind(store.$activeEvents, to: \.activeEvents)
        bind(store.$productReels, to: \.productReels)
        bind(store.$sellers, to: \.sellers)

        // eventBox có side-effect riêng (map eventBoxProducts) nên viết tay, không qua helper.
        store.$eventBox
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] value in
                guard let self else { return }
                self.eventBox = value
                self.eventBoxProducts = self.mapEventBoxProducts(value)
            }
            .store(in: &cancellables)
    }

    private func mapEventBoxProducts(_ eventBox: [EventBox]) -> [ShopProduct] {
        eventBox.first.map { HomeDTOMapper.eventPageProducts(from: $0.pageData) } ?? []
    }

    private func apply(_ snapshot: HomeCatalog) {
        categories = snapshot.categories
        banners = snapshot.banners
        exclusiveOffers = snapshot.bigDeals
        bestSelling = snapshot.recommendations
        recentlyViewed = snapshot.recentlyViewed
        eventBox = snapshot.eventBox
        eventBoxProducts = mapEventBoxProducts(snapshot.eventBox)
        activeEvents = snapshot.activeEvents
        productReels = snapshot.productReels
        sellers = snapshot.sellers
    }
}
