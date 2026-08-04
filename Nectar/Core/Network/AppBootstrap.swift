import Foundation

/// Prefetch lúc splash — ủy quyền Data layer Shop.
enum AppBootstrap {
    @discardableResult
    static func prefetchLaunchAPIs() async -> [HomeBanner] {
        await HomeRepository.shared.prefetchLaunchBanners()
        return await MainActor.run { HomeCatalogStore.shared.banners }
    }
}
