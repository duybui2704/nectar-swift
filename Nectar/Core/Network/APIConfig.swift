import Foundation

/// Envelope chuẩn Printerval: `{ "status": "successful", "result": ..., "meta": ... }`.
struct APIEnvelope<T: Decodable>: Decodable {
    let status: String
    let result: T?
    let message: String?
}

/// Môi trường chạy app.
enum AppEnvironment: String, CaseIterable {
    case production
    case staging

    static var current: AppEnvironment {
        #if DEBUG
        .production
        #else
        .production
        #endif
    }
}

/// Các microservice Printerval.
enum APIService: String, CaseIterable {
    case customer
    case order
    case variant
    case suggestion
    /// JSONPlaceholder — demo repository cũ.
    case demo

    var host: String {
        switch self {
        case .demo:
            return "https://jsonplaceholder.typicode.com"
        case .customer:
            return "https://customer-service.printerval.com"
        case .order:
            return "https://order-service.printerval.com"
        case .variant:
            return "https://variant-service.printerval.com"
        case .suggestion:
            return "https://suggestion.printerval.com"
        }
    }

    var baseURL: URL {
        URL(string: host)!
    }
}

/// Endpoint paths theo từng service.
enum APIEndpoint {
    // Bootstrap (mở app)
    static let wishlist = "wishlist"
    static let localization = "localization"
    static let homeBanners = "home/get-banners"
    static let homeCategories = "home/get-categories"
    static let categoryTree = "category/tree"
    // Home (Shop)
    static let sellerSpotlight = "seller/spotlight"
    static let recommendationProducts = "recommendation/products"
    static let activeEvent = "get-active-event"
    static let testimonial = "testimonial"
    static let todayBigDeals = "today-big-deals"
    static let recentlyViewed = "product/recently-viewed"
    static let cart = "cart"
    static let configPayment = "config-payment"
    static let location = "location"

    static func userTags(userId: String) -> String {
        "users/\(userId)/tags"
    }
}

enum APIConfig {
    static let requestTimeout: TimeInterval = 15
    static let resourceTimeout: TimeInterval = 30
    /// Timeout đã chờ lâu — retry thêm lần nữa thường lãng phí; chỉ retry lỗi mạng ngắn.
    static let maxTimeoutRetries = 0

    /// Printerval success: `"status": "successful"`.
    static let successStatus = "successful"

    static var environment: AppEnvironment { .current }
    static var baseURL: URL { APIService.customer.baseURL }

    static let acceptHeader = "application/json"
    static let contentTypeHeader = "application/json"

    static var userAgent: String { DeviceInfo.userAgent }

    static var defaultHeaders: [String: String] {
        [
            "Accept": acceptHeader,
            "Content-Type": contentTypeHeader,
            // Cloudflare / Printerval đọc header này — phải đúng casing + format PrintervalApp.
            "User-Agent": userAgent,
        ]
    }
}
