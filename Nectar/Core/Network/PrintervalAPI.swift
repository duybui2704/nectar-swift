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
    
    static func fetchSellerSpotlight() async throws -> Data {
        try await APIClient.shared.getData(
            APIEndpoint.sellerSpotlight,
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

    // MARK: - Auth

    /// `POST customer/login` — body email/password/fingerprint/country.
    static func login(
        email: String,
        password: String,
        fingerprint: String = AppIdentity.deviceId,
        country: String = AppIdentity.country
    ) async throws -> Data {
        try await APIClient.shared.postData(
            APIEndpoint.customerLogin,
            service: .customer,
            body: LoginRequestBody(
                email: email,
                password: password,
                fingerprint: fingerprint,
                country: country
            ),
            authenticated: false
        )
    }

    // MARK: - Product detail

    static func fetchProduct(id: String) async throws -> Data {
        try await APIClient.shared.getData(
            APIEndpoint.product(id),
            service: .variant,
            authenticated: false
        )
    }

    static func fetchProductGallery(id: String) async throws -> Data {
        try await APIClient.shared.getData(
            APIEndpoint.productGallery(id),
            service: .variant,
            authenticated: false
        )
    }

    static func fetchProductVariant(id: String) async throws -> Data {
        try await APIClient.shared.getData(
            APIEndpoint.productVariant(id),
            service: .variant,
            query: ["format": "1"],
            authenticated: false
        )
    }

    static func fetchProductBulkPrice(id: String) async throws -> Data {
        try await APIClient.shared.getData(
            APIEndpoint.productBulkPrice(id),
            service: .variant,
            authenticated: false
        )
    }

    static func fetchProductColorGuide(id: String) async throws -> Data {
        try await APIClient.shared.getData(
            APIEndpoint.productColorGuide(id),
            service: .variant,
            authenticated: false
        )
    }

    static func fetchProductRelated(id: String) async throws -> Data {
        try await APIClient.shared.getData(
            APIEndpoint.productRelated(id),
            service: .variant,
            authenticated: false
        )
    }

    static func fetchProductRecommendationKeyword(id: String) async throws -> Data {
        try await APIClient.shared.getData(
            APIEndpoint.productRecommendationKeyword(id),
            service: .variant,
            authenticated: false
        )
    }

    static func fetchBoughtTogether(productId: String, limit: Int = 3) async throws -> Data {
        try await APIClient.shared.getData(
            APIEndpoint.boughtTogether,
            service: .variant,
            query: [
                "productId": productId,
                "limit": "\(limit)",
            ],
            authenticated: false
        )
    }
}
