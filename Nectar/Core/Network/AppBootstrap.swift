import Foundation

/// Prefetch API — chỉ gọi endpoint đang bind UI, tránh bão request cùng host.
enum AppBootstrap {

    struct LaunchPrefetchResult: Sendable {
        var banners: [HomeBanner] = []
    }

    struct HomePrefetchResult: Sendable {
        var recommendations: [ShopProduct] = []
        var bigDeals: [ShopProduct] = []
        var banners: [HomeBanner] = []
        var categories: [CategoryTree] = []
        var recentlyViewed: [ShopProduct] = []
        var eventBox: [EventBox] = []
    }

 
    static func prefetchLaunchAPIs() async -> LaunchPrefetchResult {
        await withTaskGroup(of: LaunchChunk.self) { group in
            group.addTask { await chunkLaunch(APIEndpoint.homeBanners) { try await PrintervalAPI.fetchHomeBanners() } }
            
            var result = LaunchPrefetchResult()
            print("result: \(result)")
            for await item in group {
                switch item {
                case .banners(let data):
                    let banners = HomeDTOMapper.banners(from: data)
                    result.banners = banners
                    await MainActor.run { HomeCatalogStore.shared.setBanners(banners) }
                case .discarded:
                    break
                }
            }
            return result
        }
    }

    /// Shop: big-deals + recommendations + location — tối đa 2 request song song cùng host.
    static func prefetchHomeAPIs() async -> HomePrefetchResult {
        let regionText = await MainActor.run { LocalizationStore.shared.displayRegion }
        let cachedBanners = await MainActor.run { HomeCatalogStore.shared.banners }
        let cachedCategories = await MainActor.run { HomeCatalogStore.shared.categories }
        var result = HomePrefetchResult(banners: cachedBanners)

        // Sequential-ish: big-deals trước (UI Exclusive Offer), rồi recommendations + location song song.
        if let data = await fetchQuietly("today-big-deals", { try await PrintervalAPI.fetchTodayBigDeals() }) {
            let products = HomeDTOMapper.products(from: data)
            result.bigDeals = products
            await MainActor.run { HomeCatalogStore.shared.setBigDeals(products) }
            #if DEBUG
            print("🔥 big-deals decoded:", products.count)
            #endif
        }

        await withTaskGroup(of: HomeChunk.self) { group in
            group.addTask { await chunkHome(APIEndpoint.recommendationProducts) { try await PrintervalAPI.fetchRecommendationProducts() } }
            group.addTask { await chunkHome(APIEndpoint.categoryTree) { try await PrintervalAPI.fetchCategoryTree() } }
            group.addTask { await chunkHome(APIEndpoint.recentlyViewed) { try await PrintervalAPI.fetchRecentlyViewed() } }
            group.addTask {await chunkHome(APIEndpoint.eventBox) { try await PrintervalAPI.fetchEventBox() }}

            for await item in group {
                switch item {
                case .recommendations(let data):
                    let products = HomeDTOMapper.products(from: data)
                    result.recommendations = products
                    await MainActor.run { HomeCatalogStore.shared.setRecommendations(products) }
                    #if DEBUG
                    print("⭐ recommendations decoded:", products.count)
                    #endif
                case .recentlyViewed(let data):
                    let products = HomeDTOMapper.products(from: data)
                    result.recentlyViewed = products
                    await MainActor.run { HomeCatalogStore.shared.setRecentlyViewed(products) }
                    #if DEBUG
                    print("👀 recently viewed decoded:", products.count)
                    #endif
                case .categories(let data):
                    let categories = HomeDTOMapper.categoryTree(from: data)
                    result.categories = categories
                    await MainActor.run { HomeCatalogStore.shared.setCategories(categories) }
                    #if DEBUG
                    print("🌳 category/tree roots:", categories.count)
                    #endif
                case .eventBox(let data):
                    let eventBox = HomeDTOMapper.eventBox(from: data)
                    await MainActor.run { HomeCatalogStore.shared.setEventBox(eventBox) }
                    #if DEBUG
                    print("📢 event box:", eventBox.count)
                    #endif
                    
                case .bigDeals, .discarded:
                    break
                }
            }
        }
        result.banners = await MainActor.run { HomeCatalogStore.shared.banners }
        result.categories = await MainActor.run { HomeCatalogStore.shared.categories }
        result.recentlyViewed = await MainActor.run { HomeCatalogStore.shared.recentlyViewed }
        result.eventBox = await MainActor.run { HomeCatalogStore.shared.eventBox }
        return result
    }

    // MARK: - Private

    private enum LaunchChunk: Sendable {
        case banners(Data)
        case discarded
    }

    private enum HomeChunk: Sendable {
        case recommendations(Data)
        case bigDeals(Data)
        case categories(Data)
        case recentlyViewed(Data)
        case eventBox(Data)
        case discarded
    }

    private static func fetchQuietly(_ name: String, _ work: () async throws -> Data) async -> Data? {
        do {
            return try await work()
        } catch {
            return nil
        }
    }

    private static func chunkLaunch(_ name: String, _ work: () async throws -> Data) async -> LaunchChunk {
        do {
            let data = try await work()
            switch name {
            case APIEndpoint.homeBanners: return .banners(data)
            default: return .discarded
            }
        } catch {
            return .discarded
        }
    }

    private static func chunkHome(_ name: String, _ work: () async throws -> Data) async -> HomeChunk {
        do {
            let data = try await work()
            switch name {
            case APIEndpoint.recommendationProducts: return .recommendations(data)
            case APIEndpoint.todayBigDeals: return .bigDeals(data)
            case APIEndpoint.categoryTree: return .categories(data)
            case APIEndpoint.recentlyViewed: return .recentlyViewed(data)
            case APIEndpoint.eventBox: return .eventBox(data)
            default: return .discarded
            }
        } catch {
            return .discarded
        }
    }
}
