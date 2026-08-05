import Foundation

/// API Printerval — endpoints đang bind UI.
enum PrintervalAPI {

    static func fetchHomeBanners() async throws -> Data {
        try await APIClient.shared.getData(
            APIEndpoint.homeBanners,
            service: .variant,
            query: ["deviceId": AppIdentity.deviceId],
            authenticated: false
        )
    }

    static func fetchCategoryTree() async throws -> Data {
        try await APIClient.shared.getData(
            APIEndpoint.categoryTree,
            service: .variant,
            query: ["deviceId": AppIdentity.deviceId],
            authenticated: false
        )
    }

    static func fetchRecommendationProducts(limit: Int = AppIdentity.defaultLimit) async throws -> Data {
        try await APIClient.shared.getData(
            APIEndpoint.recommendationProducts,
            service: .variant,
            query: [
                "deviceId": AppIdentity.deviceId,
                "limit": "\(limit)",
            ],
            authenticated: false
        )
    }

    static func fetchTodayBigDeals() async throws -> Data {
        try await APIClient.shared.getData(
            APIEndpoint.todayBigDeals,
            service: .variant,
            query: ["deviceId": AppIdentity.deviceId],
            authenticated: false
        )
    }

    /// `GET product/recently-viewed`
    static func fetchRecentlyViewed(
        customerId: String = "",
        limit: Int = 20,
        page: Int = 0
    ) async throws -> Data {
        try await APIClient.shared.getData(
            APIEndpoint.recentlyViewed,
            service: .variant,
            query: [
                "customerId": customerId,
                "imei": AppIdentity.deviceId,
                "limit": "\(limit)",
                "page": "\(page)",
                "clear_cache": "1",
            ],
            authenticated: false
        )
    }

    static func fetchEventBox() async throws -> Data {
        try await APIClient.shared.getData(
            APIEndpoint.eventBox,
            service: .variant,
            authenticated: false
        )
    }

    /// `GET get-active-event` — banner event Explore + Home.
    static func fetchActiveEvent() async throws -> Data {
        try await APIClient.shared.getData(
            APIEndpoint.activeEvent,
            service: .variant,
            authenticated: false
        )
    }

    /// `GET product-video/find` — reel / product video feed.
    static func fetchProductVideos(
        pageSize: Int = 10,
        pageId: Int = 0,
        fromId: Int? = nil
    ) async throws -> Data {
        var query: [String: String] = [
            "page_size": "\(pageSize)",
            "page_id": "\(pageId)",
        ]
        if let fromId {
            query["from_id"] = "\(fromId)"
        }
        return try await APIClient.shared.getData(
            APIEndpoint.productVideoFind,
            service: .www,
            query: query,
            authenticated: false
        )
    }
}
