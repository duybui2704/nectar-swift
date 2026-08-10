import Foundation

/// Data layer Shop — fetch / map / cache. ViewModel chỉ nói chuyện qua `HomeCatalogProviding`.
@MainActor
final class HomeRepository: HomeCatalogProviding {
    static let shared = HomeRepository()

    private let store: HomeCatalogStore
    private var didLoadHome = false
    /// Shop + Explore (và mọi caller) share 1 in-flight load — tránh race decode/network.
    private var inFlightLoad: Task<HomeCatalog, Never>?

    init(store: HomeCatalogStore = .shared) {
        self.store = store
    }

    func cachedCatalog() -> HomeCatalog {
        store.snapshot()
    }

    func prefetchLaunchBanners() async {
        do {
            let data = try await PrintervalAPI.fetchHomeBanners()
            let banners = HomeDTOMapper.banners(from: data)
            store.setBanners(banners)
        } catch {
            NectarLog.log("Launch banners prefetch failed: \(error)", title: "Home")
        }
    }

    /// Prefetch home 1 lần / session — big-deals trước, rồi song song.
    /// Store cập nhật từng section → UI Home stream dần (không đợi cả group).
    func loadHomeCatalog() async -> HomeCatalog {
        if didLoadHome {
            if store.activeEvents.isEmpty {
                _ = await ensureActiveEvents()
            }
            return store.snapshot()
        }

        if let inFlightLoad {
            return await inFlightLoad.value
        }

        let task = Task { @MainActor in
            await self.performHomeLoad()
        }
        inFlightLoad = task
        let catalog = await task.value
        inFlightLoad = nil
        return catalog
    }

    func ensureActiveEvents() async -> [ActiveEvent] {
        if !store.activeEvents.isEmpty {
            return store.activeEvents
        }
        guard let data = await fetchQuietly({ try await PrintervalAPI.fetchActiveEvent() }) else {
            NectarLog.log("🎯 active events fetch failed / empty response", title: "Home")
            return []
        }
        let preview = String(data: data.prefix(800), encoding: .utf8) ?? "<binary \(data.count)>"
        NectarLog.log("🎯 get-active-event raw: \(preview)", title: "Home")
        let events = HomeDTOMapper.activeEvents(from: data)
        store.setActiveEvents(events)
        NectarLog.log("🎯 active events decoded: \(events.count)", title: "Home")
        return events
    }

    // MARK: - Private

    private func performHomeLoad() async -> HomeCatalog {
        if didLoadHome {
            return store.snapshot()
        }

        if let data = await fetchQuietly({ try await PrintervalAPI.fetchTodayBigDeals() }) {
            let products = HomeDTOMapper.products(from: data)
            store.setBigDeals(products)
            NectarLog.log("🔥 big-deals decoded: \(products.count)", title: "Home")
            // Nhường 1 frame cho scroll/layout trước khi bắn TaskGroup.
            await Task.yield()
        }

        await withTaskGroup(of: HomeChunk.self) { group in
            group.addTask { await Self.chunk(APIEndpoint.recommendationProducts) { try await PrintervalAPI.fetchRecommendationProducts() } }
            group.addTask { await Self.chunk(APIEndpoint.categoryTree) { try await PrintervalAPI.fetchCategoryTree() } }
            group.addTask { await Self.chunk(APIEndpoint.recentlyViewed) { try await PrintervalAPI.fetchRecentlyViewed() } }
            group.addTask { await Self.chunk(APIEndpoint.eventBox) { try await PrintervalAPI.fetchEventBox() } }
            group.addTask { await Self.chunk(APIEndpoint.activeEvent) { try await PrintervalAPI.fetchActiveEvent() } }
            group.addTask { await Self.chunk(APIEndpoint.productVideoFind) { try await PrintervalAPI.fetchProductVideos() } }
            group.addTask { await Self.chunk(APIEndpoint.sellerSpotlight) { try await PrintervalAPI.fetchSellerSpotlight() }}

            for await item in group {
                switch item {
                case .recommendations(let data):
                    let products = HomeDTOMapper.products(from: data)
                    store.setRecommendations(products)
                    NectarLog.log("⭐ recommendations decoded: \(products.count)", title: "Home")
                case .recentlyViewed(let data):
                    let products = HomeDTOMapper.products(from: data)
                    store.setRecentlyViewed(products)
                    NectarLog.log("👀 recently viewed decoded: \(products.count)", title: "Home")
                case .categories(let data):
                    let categories = HomeDTOMapper.categoryTree(from: data)
                    store.setCategories(categories)
                    NectarLog.log("🌳 category/tree roots: \(categories.count)", title: "Home")
                case .eventBox(let data):
                    let eventBox = HomeDTOMapper.eventBox(from: data)
                    store.setEventBox(eventBox)
                    NectarLog.log("📢 event box: \(eventBox.count)", title: "Home")
                case .activeEvent(let data):
                    let events = HomeDTOMapper.activeEvents(from: data)
                    store.setActiveEvents(events)
                    NectarLog.log("🎯 active events: \(events.count)", title: "Home")
                case .productReels(let data):
                    let reels = HomeDTOMapper.productReels(from: data)
                    store.setProductReels(reels)
                    NectarLog.log("🎬 product reels: \(reels.count)", title: "Home")
                case .sellers(let data):
                    let sellers = HomeDTOMapper.sellerSpotlight(from: data)
                    store.setSellers(sellers)
                    NectarLog.log("🏪 seller spotlight: \(sellers.count)", title: "Home")
                case .discarded:
                    break
                }
                // Trải layout/image work ra nhiều frame — tránh 1 frame “đóng băng” scroll.
                await Task.yield()
            }
        }

        didLoadHome = true
        return store.snapshot()
    }

    private enum HomeChunk: Sendable {
        case recommendations(Data)
        case categories(Data)
        case recentlyViewed(Data)
        case eventBox(Data)
        case activeEvent(Data)
        case productReels(Data)
        case sellers(Data)
        case discarded
    }

    private func fetchQuietly(_ work: () async throws -> Data) async -> Data? {
        do {
            return try await work()
        } catch {
            return nil
        }
    }

    private nonisolated static func chunk(_ name: String, _ work: () async throws -> Data) async -> HomeChunk {
        do {
            let data = try await work()
            switch name {
            case APIEndpoint.recommendationProducts: return .recommendations(data)
            case APIEndpoint.categoryTree: return .categories(data)
            case APIEndpoint.recentlyViewed: return .recentlyViewed(data)
            case APIEndpoint.eventBox: return .eventBox(data)
            case APIEndpoint.activeEvent: return .activeEvent(data)
            case APIEndpoint.productVideoFind: return .productReels(data)
            case APIEndpoint.sellerSpotlight: return .sellers(data)
            default: return .discarded
            }
        } catch {
            return .discarded
        }
    }
}
