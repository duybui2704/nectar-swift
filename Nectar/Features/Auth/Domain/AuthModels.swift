import Foundation

/// Body `POST customer/login`.
struct LoginRequestBody: Encodable {
    let email: String
    let password: String
    let fingerprint: String
    let country: String
}

/// Session sau login thành công.
struct AuthSession: Sendable, Equatable {
    let token: String
    let displayName: String
    let email: String?
    let customerId: String?
}
