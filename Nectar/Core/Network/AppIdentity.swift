import Foundation

/// Identity dùng cho query API Printerval.
/// Hiện tại **token và deviceId là một** (cùng giá trị).
enum AppIdentity {
    /// UUID thiết bị / guest id (dùng chung cho token & deviceId).
    static let deviceId = "31865C36-491B-4BC0-B693-CE1DCE09C96A"

    /// Token guest — tạm thời = `deviceId`.
    static var token: String { deviceId }

    static let country = "us"
    static let defaultLimit = 30
}
