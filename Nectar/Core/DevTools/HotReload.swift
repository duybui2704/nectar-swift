import SwiftUI

// MARK: - Hot Reload shim
//
// Cần 1 trong 2 app đang chạy:
//   - InjectionNext.app  (khuyến nghị, Xcode 15+)
//   - InjectionIII.app
//
// Hướng dẫn: docs/hot-reload.md
//
// Khi crash EXC_BAD_ACCESS + log `eval2.dylib` / `debug map object file … changed`:
 // → đó là Inject hot-reload, không phải bug app. Tắt InjectionNext rồi ⌘R lại.
// → hoặc thêm Launch Argument: -DISABLE_HOT_RELOAD

#if DEBUG && canImport(Inject)
import Inject

enum HotReloadBootstrap {
    /// Launch Argument `-DISABLE_HOT_RELOAD` → không load Injection bundle.
    static var isEnabled: Bool {
        !ProcessInfo.processInfo.arguments.contains("-DISABLE_HOT_RELOAD")
    }

    /// Gọi 1 lần khi app khởi động — trỏ Inject tới InjectionNext (fallback InjectionIII).
    static func configure() {
        guard isEnabled else {
            print("ℹ️ HotReload: disabled (-DISABLE_HOT_RELOAD)")
            return
        }

        // Inject mặc định tìm InjectionIII; với InjectionNext cần đổi path.
        let next = "/Applications/InjectionNext.app/Contents/Resources/"
        let iii = "/Applications/InjectionIII.app/Contents/Resources/"
        if FileManager.default.fileExists(atPath: next + "iOSInjection.bundle") {
            InjectConfiguration.bundlePath = next
        } else if FileManager.default.fileExists(atPath: iii + "iOSInjection.bundle") {
            InjectConfiguration.bundlePath = iii
        } else {
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
    @ViewBuilder
    func hotReload() -> some View {
        if HotReloadBootstrap.isEnabled {
            self.enableInjection()
        } else {
            self
        }
    }
}

/// Property wrapper trigger redraw khi injection xảy ra.
typealias HotReloadObserver = ObserveInjection

#else

enum HotReloadBootstrap {
    static var isEnabled: Bool { false }
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
