import Foundation

enum AppError: LocalizedError, Equatable {
    case network(String)
    case unauthorized
    case validation(String)
    case notFound
    case unknown

    var errorDescription: String? {
        switch self {
        case .network(let message): return message
        case .unauthorized: return "Phiên đăng nhập hết hạn."
        case .validation(let message): return message
        case .notFound: return "Không tìm thấy dữ liệu."
        case .unknown: return "Đã xảy ra lỗi. Vui lòng thử lại."
        }
    }
}
