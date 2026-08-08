import Foundation
import OSLog

/// Logger dùng chung toàn app — **OSLog** + prefix filter `Nectar log`.
///
/// ```swift
/// NectarLog.log("decoded 12 items")
/// // → Nectar log =>> decoded 12 items
///
/// NectarLog.log("decoded 12 items", title: "Home")
/// // → Nectar log Home =>> decoded 12 items
///
/// NectarLog.log("HTTP 500", title: "Network", level: .error)
/// ```
///
/// Filter:
/// - Xcode Console: `Nectar log`
/// - Console.app: subsystem `com.example.Nectar` + category (= title)
enum NectarLog {
    private static let base = "Nectar log"
    static let subsystem = Bundle.main.bundleIdentifier ?? "com.example.Nectar"

    enum Level {
        case debug
        case info
        case error
        case fault
    }

    /// DEBUG + Release đều ghi OSLog; Xcode thường chỉ hiện Debug session.
    /// - Parameter title: tùy chọn → category OSLog + ghép vào prefix.
    static func log(
        _ message: String,
        title: String? = nil,
        level: Level = .debug
    ) {
        let category = (title?.isEmpty == false) ? title! : "App"
        let logger = Logger(subsystem: subsystem, category: category)
        let tagged = "\(header(title)) =>> \(message)"

        switch level {
        case .debug:
            logger.debug("\(tagged, privacy: .public)")
        case .info:
            logger.info("\(tagged, privacy: .public)")
        case .error:
            logger.error("\(tagged, privacy: .public)")
        case .fault:
            logger.fault("\(tagged, privacy: .public)")
        }

        #if DEBUG
        // Giữ print để filter nhanh trong Xcode Console khi OSLog bị thu gọn.
        print(tagged)
        #endif
    }

    private static func header(_ title: String?) -> String {
        guard let title, !title.isEmpty else { return base }
        return "\(base) \(title)"
    }
}
