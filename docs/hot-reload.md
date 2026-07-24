# Hot Reload cho SwiftUI (Fast Refresh kiểu RN)

Save file → app trong simulator update ngay, **giữ nguyên state** (đang ở tab Chuyển tiền, đã nhập amount, đã ở bước OTP…). Rất giống Fast Refresh của React Native.

Repo đã được **cấu hình sẵn hoàn toàn** — bạn chỉ cần:

1. Cài **InjectionNext** (macOS app)
2. Mở Xcode → `⌘R` (Xcode tự resolve SPM Inject 1.6.0)
3. Chạy InjectionNext → Select Project → save file → 🎉

## 0. Đã cấu hình sẵn trong repo

Không cần đụng vào — chỉ tham khảo:

| Thứ | Vị trí | Vai trò |
|-----|--------|---------|
| SPM package | `project.pbxproj` — `Inject 1.6.0` (upToNextMajor) + `Package.resolved` | Đã pin sẵn, Xcode tự resolve khi mở |
| Build flag | `project.pbxproj` — `OTHER_LDFLAGS[sdk=iphonesimulator*]` = `-Xlinker -interposable` (Debug only) | Cho phép Inject "thay" hàm tại runtime |
| Shim | `Nectar/Core/DevTools/HotReload.swift` | `@HotReloadObserver` + `.hotReload()` — chuyển thẳng sang Inject.ObserveInjection |
| View đã bật | `RootView`, `MainShellView`, `LoginView`, `OnboardingView`, `DashboardView`, `HistoryView`, `TransferView` | Đã có `@HotReloadObserver` + `.hotReload()` |

**Bảo mật:** flag `-Xlinker -interposable` chỉ áp cho `iphonesimulator*` — build device / release **không có** flag này, không có tác động runtime.

---

## 1. Cài InjectionNext (bắt buộc — không có app thì Hot Reload không chạy)

Cảnh báo `InjectionIII bundle not found` = máy **chưa có** app Injection. SPM `Inject` chỉ là client; app mới chứa `iOSInjection.bundle`.

**Cài thủ công (khuyến nghị):**

```bash
# 1. Tải bản mới nhất
open "https://github.com/johnno1962/InjectionNext/releases/latest"

# 2. Giải nén InjectionNext.zip → kéo InjectionNext.app vào /Applications

# 3. Mở app
open /Applications/InjectionNext.app
```

Verify bundle tồn tại:

```bash
ls /Applications/InjectionNext.app/Contents/Resources/iOSInjection.bundle
```

Nếu lệnh trên báo "No such file" → app chưa cài đúng chỗ.

Mở `InjectionNext.app` — icon 💉 xuất hiện trên menu bar.

> **Vì sao dùng InjectionNext thay vì InjectionIII cũ?**
> InjectionNext (2024+) tối ưu cho Xcode 15/16/26, không cần bundle inject cồng kềnh, hoạt động cả với macros. Nếu bạn kẹt Xcode cũ, dùng [InjectionIII](https://github.com/johnno1962/InjectionIII) đều được — flags trong repo cùng dùng chung.

---

## 2. Xcode tự resolve package

`Package.resolved` đã pin `Inject 1.6.0` trong repo, nên khi bạn mở project lần đầu:

```bash
open Nectar.xcodeproj
```

Xcode sẽ tự fetch package (thấy dòng "Resolving Package Dependencies…" góc trên). Đợi 5–10 giây xong là dùng được.

**Nếu resolve fail** (mạng chặn GitHub, hoặc muốn refresh):
- Menu Xcode: **File → Packages → Reset Package Caches** rồi **File → Packages → Resolve Package Versions**.

Không cần "Add Package Dependencies" thủ công nữa.

---

## 3. Cấu hình InjectionNext theo dõi thư mục

1. Click icon 💉 trên menu bar → **Select Project…**
2. Chọn thư mục `~/Documents/Nectar` (chứa `.xcodeproj`)
3. Menu 💉 → tick **Xcode Project (last opened)** hoặc **File Watcher**

Khi Xcode đang chạy app, InjectionNext sẽ theo dõi mọi `.swift` bên trong.

---

## 4. Chạy thử

1. Chọn scheme **Nectar**, target **iPhone 16 Simulator** (hoặc bất kỳ simulator iOS 17+).
2. `⌘R` — app khởi động, đăng nhập `demo` / `123456`.
3. Trong console Xcode, tìm dòng:
   ```
   💉 Injection connected 12345…
   💉 Watching /Users/.../Nectar
   ```
   Có nghĩa Inject đã kết nối OK.
4. Mở `LoginView.swift` → đổi:
   ```swift
   Text("Nectar")
   ```
   thành `Text("Nectar 🔥")`, **⌘S**.
5. Console in `💉 Compiling … Loaded .dylib …`, simulator hiển thị "Nectar 🔥" **ngay lập tức**, không cần rebuild toàn app.

Test tiếp:
- Thay đổi `BankColors.brand` trong `BankColors.swift` — mọi màu brand đổi ngay.
- Ở màn Transfer bước OTP đã nhập 3 số → sửa layout `TransferView.swift` → save → 3 số **vẫn còn**, chỉ UI đổi.
- Sửa spacing trong `WalletCardView.swift` → Dashboard update.

---

## 5. Cách hot reload thực sự hoạt động

```
save file A.swift
     ↓
InjectionNext detect thay đổi
     ↓
compile riêng A.swift → A.dylib
     ↓
send qua socket vào simulator
     ↓
dlopen(A.dylib) → swizzle các function trong A
     ↓
@ObserveInjection trigger → SwiftUI redraw body
     ↓
UI update, state @State/@StateObject giữ nguyên
```

Chi tiết kỹ thuật:
- Flag `-Xlinker -interposable` bắt linker tạo **indirection table** cho mọi function → runtime có thể "swizzle" chúng.
- `@ObserveInjection` (được `typealias` thành `HotReloadObserver`) subscribe vào notification `INJECTION_BUNDLE_NOTIFICATION` — mỗi lần nhận notif thì `objectWillChange` → SwiftUI diff & rebuild body.
- State (`@State`, `@StateObject`, `@Published`) sống ở **storage riêng** ngoài struct View → giữ nguyên qua các lần rebuild body.

---

## 6. Giới hạn (biết trước để không bực)

Cái **được** hot reload:
- Thân `body` của View — layout, style, modifier
- Nội dung method trong class/struct
- Hằng số cục bộ

Cái **KHÔNG** hot reload — phải rebuild:
- Thay đổi type signature (thêm/bỏ property `@State`, đổi kiểu `@Published`, thêm case enum)
- Thêm/xóa file `.swift` (phải rebuild toàn dự án)
- Thêm/xóa import
- Thay đổi trong file `.plist`, `.xcassets`, `.strings`
- Chỉnh Info.plist, capabilities, entitlements
- Sửa protocol/generic phức tạp — đôi khi crash → hãy `⌘R` lại

**Ứng xử khi Inject crash:**
- Console báo `💉 Load error` — thường do type mismatch: rebuild toàn app (`⌘R`) là hết.
- Không hoạt động trên **device thật** (ta chỉ set flag cho simulator để bảo mật).

---

## 7. Gắn hot reload cho View mới

Đối với View bất kỳ bạn muốn hot-reload:

```swift
import SwiftUI

struct MyNewView: View {
    @State private var value = ""
    @HotReloadObserver private var _hr   // 1. thêm property wrapper

    var body: some View {
        VStack {
            Text("Hello")
            TextField("x", text: $value)
        }
        .hotReload()                     // 2. bọc ở modifier cuối cùng
    }
}
```

Chỉ cần 2 dòng. Nếu bỏ 1 trong 2, view vẫn compile & chạy — nhưng sẽ **không** tự refresh (các View khác vẫn refresh bình thường).

**Tip:** thêm mặc định cho mọi View mới — không hại (no-op ở Release).

---

## 8. Tại sao KHÔNG chỉ dùng Xcode Preview?

Xcode Preview (`#Preview`) render **một View riêng lẻ** với dữ liệu mock. Rất tốt để chỉnh 1 component.

Hot reload (Inject) chạy **toàn app runtime**: bạn đang ở màn Transfer bước OTP, đã nhập số, thấy real data → sửa & thấy đổi luôn, không lạc mất context. Đây là workflow gần nhất với **RN Fast Refresh**.

Best practice: dùng **Preview** khi build component mới; dùng **Hot Reload** khi tinh chỉnh flow phức tạp và cần giữ state.

---

## 9. Tắt hot reload

Không cần code — chỉ cần **thoát InjectionNext.app**. `HotReloadObserver` sẽ không nhận notification, app chạy như bình thường.

Nếu muốn tắt hoàn toàn (kể cả compile flag), xóa dòng `OTHER_LDFLAGS[sdk=iphonesimulator*]` trong `project.pbxproj` (config Debug của target `Nectar`).

---

## 10. Troubleshoot

| Triệu chứng | Nguyên nhân | Fix |
|-------------|-------------|-----|
| Console không thấy `💉 Injection connected` | InjectionNext chưa chạy hoặc chưa chọn project | Mở app, Select Project |
| Console có `💉 connected` nhưng save file không update | Quên `.hotReload()` ở View đó | Thêm modifier |
| `💉 Load error … undefined symbol` | Đã đổi type signature | `⌘R` rebuild |
| Xcode 26 báo "Interposing disabled" | Xcode security update chặn interposing trên simulator mới | Kiểm tra scheme → Diagnostics → tick **Debug executable**; hoặc dùng InjectionNext bản mới nhất |
| Simulator chạy device thật | Flag không áp cho device | Đúng thiết kế — hot reload chỉ simulator |
| Build fail "cannot find 'Inject'" | Chưa add SPM package | Bước 2 |
| Build OK nhưng `.hotReload()` không effect | Chạy Release scheme | Đổi sang Debug |

---

## Đọc thêm

- Repo Inject: <https://github.com/krzysztofzablocki/Inject>
- InjectionNext: <https://github.com/johnno1962/InjectionNext>
- Bài viết gốc "Hot reloading Swift": <https://www.merowing.info/hot-reloading-in-swift/>
- WWDC video liên quan concurrency & structured build: search "SwiftUI Previews" trên developer.apple.com
