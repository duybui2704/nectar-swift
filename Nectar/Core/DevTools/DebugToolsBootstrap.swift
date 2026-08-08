import Foundation

/// Bootstrap DEBUG tooling — OSLog smoke-test + gợi ý Proxyman.
/// Không đổi URLSession / không pin cert → Proxyman MITM hoạt động khi đã trust CA.
enum DebugToolsBootstrap {
    static func configure() {
        #if DEBUG
        NectarLog.log(
            "OSLog ready — subsystem: \(NectarLog.subsystem) | filter: \"Nectar log\"",
            title: "Debug",
            level: .info
        )
        NectarLog.log(
            "Proxyman: Certificate → Install for iOS Simulators; SSL Proxying *.printerval.com — xem docs/debugging-oslog-proxyman.md",
            title: "Debug",
            level: .info
        )
        #endif
    }
}
