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

/// Các microservice Printerval đang dùng.
enum APIService: String, CaseIterable {
    case customer
    case order
    case variant
    /// Website gốc `printerval.com` (product-video, …).
    case www

    var host: String {
        switch self {
        case .customer:
            return "https://customer-service.printerval.com"
        case .order:
            return "https://order-service.printerval.com"
        case .variant:
            return "https://variant-service.printerval.com"
        case .www:
            return "https://printerval.com"
        }
    }

    var baseURL: URL {
        URL(string: host)!
    }
}

/// Endpoint paths theo từng service (chỉ path đang bind UI).
enum APIEndpoint {
    static let homeBanners = "home/get-banners"
    static let categoryTree = "category/tree"
    static let recommendationProducts = "recommendation/products"
    static let todayBigDeals = "today-big-deals"
    static let recentlyViewed = "product/recently-viewed"
    static let eventBox = "event-box"
    /// `GET product-video/find` trên `printerval.com`.
    static let productVideoFind = "product-video/find"
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
