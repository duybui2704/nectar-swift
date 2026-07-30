import Foundation

/// API Printerval — bootstrap (mở app) + home (Shop).
enum PrintervalAPI {

    // MARK: - Bootstrap (gọi khi mở app)

    static func fetchWishlist(country: String = AppIdentity.country) async throws -> Data {
        try await APIClient.shared.getData(
            APIEndpoint.wishlist,
            service: .customer,
            query: [
                "token": AppIdentity.token,
                "country": country,
            ],
            authenticated: false
        )
    }

    static func fetchLocalization() async throws -> Data {
        try await APIClient.shared.getData(
            APIEndpoint.localization,
            service: .variant,
            authenticated: false
        )
    }

    static func fetchHomeBanners() async throws -> Data {
        try await APIClient.shared.getData(
            APIEndpoint.homeBanners,
            service: .variant,
            query: ["deviceId": AppIdentity.deviceId],
            authenticated: false
        )
    }

    static func fetchHomeCategories() async throws -> Data {
        try await APIClient.shared.getData(
            APIEndpoint.homeCategories,
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

    // MARK: - Home / Shop

    static func fetchSellerSpotlight() async throws -> Data {
        try await APIClient.shared.getData(
            APIEndpoint.sellerSpotlight,
            service: .variant,
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

    static func fetchUserTags(k: Int = 15) async throws -> Data {
        try await APIClient.shared.getData(
            APIEndpoint.userTags(userId: AppIdentity.token),
            service: .suggestion,
            query: ["k": "\(k)"],
            authenticated: false
        )
    }

    static func fetchActiveEvent() async throws -> Data {
        try await APIClient.shared.getData(
            APIEndpoint.activeEvent,
            service: .variant,
            authenticated: false
        )
    }

    static func fetchTestimonial() async throws -> Data {
        try await APIClient.shared.getData(
            APIEndpoint.testimonial,
            service: .variant,
            query: ["deviceId": AppIdentity.deviceId],
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

    static func fetchCart() async throws -> Data {
        try await APIClient.shared.getData(
            APIEndpoint.cart,
            service: .order,
            query: ["token": AppIdentity.token],
            authenticated: false
        )
    }

    static func fetchLocation() async throws -> Data {
        try await APIClient.shared.getData(
            APIEndpoint.location,
            service: .variant,
            authenticated: false
        )
    }
}
