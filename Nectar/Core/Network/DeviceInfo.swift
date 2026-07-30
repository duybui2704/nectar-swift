import Foundation
import UIKit

/// Thông tin thiết bị cho User-Agent (tách khỏi APIConfig).
///
/// Printerval/Cloudflare thường **chặn** request có `Simulator` trong UA
/// hoặc UA không đúng format `PrintervalApp/IOS/...`.
enum DeviceInfo {
    /// Format khớp app Printerval gốc — bắt buộc để API không trả 403 HTML.
    static var userAgent: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.6.8"
        let model = UIDevice.current.printervalModelName
        let system = UIDevice.current.systemVersion
        let scale = String(format: "%.2f", UIScreen.main.scale)
        return "PrintervalApp/IOS/\(version) (\(model); iOS \(system); scale/\(scale))"
    }
}

private extension UIDevice {
    /// Tên model cho UA. Simulator **không** được gửi chữ "Simulator" (CF hay 403).
    var printervalModelName: String {
        #if targetEnvironment(simulator)
        return "iPhone XS Max"
        #else
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        let identifier = mirror.children.reduce(into: "") { result, element in
            guard let value = element.value as? Int8, value != 0 else { return }
            result.append(String(UnicodeScalar(UInt8(value))))
        }

        switch identifier {
        case "iPhone11,2": return "iPhone XS"
        case "iPhone11,4", "iPhone11,6": return "iPhone XS Max"
        case "iPhone14,5": return "iPhone 13"
        case "iPhone15,2": return "iPhone 14 Pro"
        case "iPhone16,2": return "iPhone 15 Pro Max"
        case "iPhone17,2": return "iPhone 16 Pro Max"
        default:
            return identifier.isEmpty ? "iPhone" : identifier
        }
        #endif
    }
}
