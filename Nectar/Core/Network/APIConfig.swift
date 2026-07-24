import Foundation

struct APIEnvelope<T: Decodable>: Decodable {
    let code: String
    let message: String
    let body: T?
}

enum APIConfig {
    static let successCode = "API000"
    static let jwtRefreshCode = "JWT-001"
    static let jwtLogoutCode = "JWT-002"
    static let appHeader = "postpay"
    static let requestTimeout: TimeInterval = 30

    /// JSONPlaceholder for demo real HTTP; swap to PostPay base URL in production.
    static let baseURL = URL(string: "https://jsonplaceholder.typicode.com")!
    static let postPayBaseURL = URL(string: "https://vnpd-o2o-dev.postpay.vn/cake-cbd7443c61e8")!
}
