import Foundation

/// Mock identity / delay cho Login & Profile (chưa nối auth API thật).
enum MockNectarAPI {
    static let customerName = "Nguyễn Văn A"
    static let phoneMasked = "090****321"

    static func delay(_ ms: UInt64 = 450) async {
        try? await Task.sleep(nanoseconds: ms * 1_000_000)
    }
}
