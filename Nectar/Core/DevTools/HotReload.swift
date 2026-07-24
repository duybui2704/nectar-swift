import SwiftUI

// MARK: - Hot Reload shim
//
// Cần 1 trong 2 app đang chạy:
//   - InjectionNext.app  (khuyến nghị, Xcode 15+)
//   - InjectionIII.app
//
// Hướng dẫn: docs/hot-reload.md

#if DEBUG && canImport(Inject)
import Inject

enum HotReloadBootstrap {
    /// Gọi 1 lần khi app khởi động — trỏ Inject tới InjectionNext (fallback InjectionIII).
    static func configure() {
        // Inject mặc định tìm InjectionIII; với InjectionNext cần đổi path.
        // Inject 1.6+ cũng tự thử thay "III" → "Next", nhưng set tường minh cho rõ.
        let next = "/Applications/InjectionNext.app/Contents/Resources/"
        let iii = "/Applications/InjectionIII.app/Contents/Resources/"
        if FileManager.default.fileExists(atPath: next + "iOSInjection.bundle") {
            InjectConfiguration.bundlePath = next
        } else if FileManager.default.fileExists(atPath: iii + "iOSInjection.bundle") {
            InjectConfiguration.bundlePath = iii
        } else {
            // Giữ default; Inject sẽ print warning nếu không tìm thấy
            InjectConfiguration.bundlePath = next
            print("""
            ⚠️ HotReload: Chưa cài InjectionNext / InjectionIII.
               1. Tải: https://github.com/johnno1962/InjectionNext/releases
               2. Giải nén → kéo InjectionNext.app vào /Applications
               3. Mở InjectionNext → Select Project → thư mục Nectar
               4. ⌘R lại app trong Xcode
            """)
        }
        _ = InjectConfiguration.load
    }
}

extension View {
    /// Bật hot reload — save file → app cập nhật ngay (chỉ DEBUG).
    func hotReload() -> some View {
        self.enableInjection()
    }
}

/// Property wrapper trigger redraw khi injection xảy ra.
typealias HotReloadObserver = ObserveInjection

#else

enum HotReloadBootstrap {
    static func configure() {}
}

extension View {
    func hotReload() -> some View { self }
}

@propertyWrapper
struct HotReloadObserver: DynamicProperty {
    init() {}
    var wrappedValue: Int { 0 }
}

#endif
