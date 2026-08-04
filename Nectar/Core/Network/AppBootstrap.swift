import Foundation

/// Prefetch API — chỉ gọi endpoint đang bind UI, tránh bão request cùng host.
enum AppBootstrap {

    struct LaunchPrefetchResult: Sendable {
        var localization: LocalizationPayload?
        var banners: [HomeBanner] = []
    }

    struct HomePrefetchResult: Sendable {
        var location: LocationResult? = nil
        var regionText: String
        var recommendations: [ShopProduct] = []
        var bigDeals: [ShopProduct] = []
        var banners: [HomeBanner] = []
        var categories: [CategoryTree] = []
    }

 
    static func prefetchLaunchAPIs() async -> LaunchPrefetchResult {
        await withTaskGroup(of: LaunchChunk.self) { group in
            group.addTask { await chunkLaunch(APIEndpoint.homeBanners) { try await PrintervalAPI.fetchHomeBanners() } }
            
            var result = LaunchPrefetchResult()
            for await item in group {
                switch item {
                case .localization(let data):
                    do {
                        let payload = try LocalizationPayload.decode(from: data)
                        result.localization = payload
                        await MainActor.run { LocalizationStore.shared.apply(payload) }
                    } catch {
                        #if DEBUG
                        print("⚠️ Bootstrap[localization] decode failed:", error)
                        #endif
                    }
                case .banners(let data):
                    let banners = HomeDTOMapper.banners(from: data)
                    result.banners = banners
                    await MainActor.run { HomeCatalogStore.shared.setBanners(banners) }
                    #if DEBUG
                    print("🖼️ banners decoded:", banners.count)
                    #endif
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
        var result = HomePrefetchResult(regionText: regionText, banners: cachedBanners)

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
            group.addTask { await chunkHome("recommendation/products") { try await PrintervalAPI.fetchRecommendationProducts() } }
            group.addTask { await chunkHome("location") { try await PrintervalAPI.fetchLocation() } }
            group.addTask { await chunkHome("category/tree") { try await PrintervalAPI.fetchCategoryTree() } }

            for await item in group {
                switch item {
                case .location(let data):
                    do {
                        result.location = try LocationResult.decode(from: data)
                    } catch {
                        #if DEBUG
                        print("⚠️ Bootstrap[location] decode failed:", error)
                        #endif
                    }
                case .recommendations(let data):
                    let products = HomeDTOMapper.products(from: data)
                    result.recommendations = products
                    await MainActor.run { HomeCatalogStore.shared.setRecommendations(products) }
                    #if DEBUG
                    print("⭐ recommendations decoded:", products.count)
                    #endif
                case .categories(let data):
                    let categories = HomeDTOMapper.categoryTree(from: data)
                    print("🔍 categories: \(categories)")
                    result.categories = categories
                    await MainActor.run { HomeCatalogStore.shared.setCategories(categories) }
                    #if DEBUG
                    print("🌳 category/tree roots:", categories.count)
                    #endif
                case .bigDeals, .discarded:
                    break
                }
            }
        }

        result.regionText = await MainActor.run { LocalizationStore.shared.displayRegion }
        result.banners = await MainActor.run { HomeCatalogStore.shared.banners }
        result.categories = await MainActor.run { HomeCatalogStore.shared.categories }
        return result
    }

    // MARK: - Private

    private enum LaunchChunk: Sendable {
        case localization(Data)
        case banners(Data)
        case discarded
    }

    private enum HomeChunk: Sendable {
        case location(Data)
        case recommendations(Data)
        case bigDeals(Data)
        case discarded
        case categories(Data)
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
            case "localization": return .localization(data)
            case "home/banners": return .banners(data)
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
            case "location": return .location(data)
            case "recommendation/products": return .recommendations(data)
            case "today-big-deals": return .bigDeals(data)
            case "category/tree": return .categories(data)
            default: return .discarded
            }
        } catch {
            return .discarded
        }
    }
}
