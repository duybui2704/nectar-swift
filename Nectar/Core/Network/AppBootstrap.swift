import Foundation

/// Prefetch API — chỉ gọi endpoint đang decode / bind UI.
enum AppBootstrap {

    struct LaunchPrefetchResult {
        var localization: LocalizationPayload?
        var banners: [HomeBanner] = []
    }

    struct HomePrefetchResult {
        var location: LocationResult? = nil
        var regionText: String
        var recommendations: [ShopProduct] = []
        var bigDeals: [ShopProduct] = []
        var banners: [HomeBanner] = []
    }

    /// Splash: localization + banners (song song).
    @MainActor
    static func prefetchLaunchAPIs() async -> LaunchPrefetchResult {
        await withTaskGroup(of: LaunchChunk.self) { group in
            group.addTask { await chunkLaunch("localization") { try await PrintervalAPI.fetchLocalization() } }
            group.addTask { await chunkLaunch("home/banners") { try await PrintervalAPI.fetchHomeBanners() } }

            var result = LaunchPrefetchResult()
            print("LaunchPrefetchResult result: \(result)")
            for await item in group {
                switch item {
                case .localization(let data):
                    do {
                        let payload = try LocalizationPayload.decode(from: data)
                        result.localization = payload
                        LocalizationStore.shared.apply(payload)
                    } catch {
                        #if DEBUG
                        print("⚠️ Bootstrap[localization] decode failed:", error)
                        #endif
                    }
                case .banners(let data):
                    let banners = HomeDTOMapper.banners(from: data)
                    result.banners = banners
                    HomeCatalogStore.shared.setBanners(banners)
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

    /// Shop: location + recommendations + big-deals (song song).
    @MainActor
    static func prefetchHomeAPIs() async -> HomePrefetchResult {
        await withTaskGroup(of: HomeChunk.self) { group in
            group.addTask { await chunkHome("recommendation/products") { try await PrintervalAPI.fetchRecommendationProducts() } }
            group.addTask { await chunkHome("today-big-deals") { try await PrintervalAPI.fetchTodayBigDeals() } }
            group.addTask { await chunkHome("location") { try await PrintervalAPI.fetchLocation() } }

            var result = HomePrefetchResult(
                regionText: LocalizationStore.shared.displayRegion,
                banners: HomeCatalogStore.shared.banners
            )

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
                    HomeCatalogStore.shared.setRecommendations(products)
                    #if DEBUG
                    print("⭐ recommendations decoded:", products.count)
                    #endif
                case .bigDeals(let data):
                    let products = HomeDTOMapper.products(from: data)
                    result.bigDeals = products
                    HomeCatalogStore.shared.setBigDeals(products)
                    #if DEBUG
                    print("🔥 big-deals decoded:", products.count)
                    #endif
                case .discarded:
                    break
                }
            }

            result.regionText = LocalizationStore.shared.displayRegion
            result.banners = HomeCatalogStore.shared.banners
            return result
        }
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
            #if DEBUG
            print("⚠️ Bootstrap[\(name)] failed: \(error.localizedDescription)")
            #endif
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
            default: return .discarded
            }
        } catch {
            #if DEBUG
            print("⚠️ Bootstrap[\(name)] failed: \(error.localizedDescription)")
            #endif
            return .discarded
        }
    }
}
