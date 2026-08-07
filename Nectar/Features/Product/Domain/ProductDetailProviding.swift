import Foundation

/// Domain port — ViewModel chỉ phụ thuộc protocol này.
@MainActor
protocol ProductDetailProviding: AnyObject {
    func loadCritical(productId: String) async -> ProductCriticalLoadResult
    func loadSecondary(productId: String) async -> ProductDetailSnapshot
}

struct ProductCriticalLoadResult: Sendable {
    var snapshot: ProductDetailSnapshot
    /// Lỗi network/HTTP của `product/{id}` (nếu có).
    var productError: String?
    /// `true` khi HTTP OK nhưng body không map được product.
    var productParseFailed: Bool
}
