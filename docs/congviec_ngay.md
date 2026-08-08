# Công việc ngày — 8/8/2026

Tóm tắt **kiến thức Swift/SwiftUI riêng** học được trong ngày và **công việc đã làm** trên repo Nectar.

---

## 1. Công việc đã làm

### Seller Spotlight + merge remote
- Fix mapper `seller/spotlight` (không còn `init(jsonObject:)` giả).
- Pull/merge `feat: product detail` vào `main`, resolve conflict (`APIConfig`, `ProductCardView`, `ProductHorizontalRail`).
- Wire data: API → Repository → Store → ViewModel → `SellerSpotlight` UI.
- Push `main` lên origin.

### Logging chuẩn (OSLog + NectarLog)
- Tạo `NectarLog` — prefix filter `Nectar log`, optional `title`, level `.debug/.info/.error/.fault`.
- `NetworkLogger` đi qua OSLog (category `Network`).
- Docs: `docs/debugging-oslog-proxyman.md` (OSLog + Proxyman + shared Breakpoints).

### Login API thật
- `POST customer/login` (email, password, fingerprint, country).
- Đổi ô phone/stk → **Username**, prefill `test1@gmail.com` / `123456`.
- `AuthRepository` + `AuthDTOMapper` + lưu token Keychain qua `AppSession.loginSucceeded(session:)`.

### Skeleton loading toàn app
- Hệ shimmer dùng chung: `SkeletonBone` / `SkeletonScope` / `.skeleton(isLoading:)`.
- Preset layout: banner, category, product rail, reels, seller, event.
- Wire từng section Home theo flag `isLoading && data.isEmpty`.
- Docs: `docs/skeleton-loading.md`.

### Fix giật scroll cuối Home
- EventBox: **không** parse JSON `pageData` trong `body` — parse sẵn ở ViewModel.
- SellerSpotlight: chỉnh `GridItem` / frame cố định tránh layout thrash.
- Tab bar: throttle ẩn/hiện khi rubber-band cuối list.

---

## 2. Kiến thức Swift / SwiftUI học hôm nay

### 2.1. `compactMap` + member init
```swift
rows.compactMap(Sellers.init(jsonObject:)) // ❌ chỉ compile nếu type có init đó
```
Struct `Codable` **không** tự có `init(jsonObject:)`. Parse linh hoạt → `[String: Any]` + helper, hoặc `JSONDecoder`.

### 2.2. Optional binding với Array
```swift
if let sellers = viewModel.sellers { } // ❌ [Sellers] không phải Optional
if !viewModel.sellers.isEmpty { }      // ✅
```

### 2.3. OSLog vs `print`
| | `print` | `Logger` (OSLog) |
|--|---------|------------------|
| Filter | text thô | subsystem + category |
| Release | dễ lộ | level / privacy |
| Xcode | Console | Console + Console.app |

Pattern Nectar:
```swift
NectarLog.log("message", title: "Home", level: .info)
// → Nectar log Home =>> message
// OSLog category = title
```

### 2.4. URLSession + Proxyman
- Không certificate pinning → Proxyman MITM được sau khi trust CA.
- Simulator: Certificate → Install for iOS Simulators + SSL Proxying `*.printerval.com`.
- `URLSessionConfiguration.default` + system trust là đủ cho dev.

### 2.5. Shared Xcode Breakpoints
File: `*.xcodeproj/xcshareddata/xcdebugger/Breakpoints_v2.xcbkptlist`  
→ commit được, cả team thấy trong Breakpoint Navigator (`⌘8`).  
Hữu ích: Exception, Swift Error, `UIViewAlertForUnsatisfiableConstraints`.

### 2.6. Auth flow SwiftUI
```
View → ViewModel → Repository → APIClient.postData
     → Mapper → AuthSession(token, displayName)
     → AppSession lưu Keychain → route = .main
```
- Login phải `authenticated: false`.
- Đọc `message` từ body khi HTTP 4xx (không chỉ `"HTTP 401"`).
- Không tạo token giả sau login thật (`saveSession(token:)`).

### 2.7. Skeleton theo section (không full-screen)
```swift
.content
  .skeleton(isLoading: isLoading && items.isEmpty) {
      SkeletonLayout.productRail()
  }
```
- `SkeletonScope` + `@Environment` phase → mọi bone shimmer sync.
- Điều kiện `isLoading && isEmpty` tránh che data đã cache.

### 2.8. Performance scroll (LazyVStack)
Nguyên nhân giật cuối list thường gặp:
1. **Work nặng trong `body`** (JSON parse, map lớn) mỗi lần materialize.
2. **Layout không cố định** (grid height lệch content) → đo lại khi ảnh load.
3. **`@Published` spam** (tab bar toggle mỗi bounce) → shell re-render giữa scroll.

Bài học:
- Parse / map **trước** khi vào View (ViewModel / Repository).
- Cho rail/grid **chiều cao cố định** khi có thể.
- Throttle side-effect gắn scroll (tab bar, analytics).

### 2.9. Git diverge / merge
Local và remote mỗi bên 1 commit → `git pull --no-rebase`, resolve conflict, commit merge.  
Không amend/push force trừ khi được yêu cầu rõ.

---

## 3. File / docs quan trọng trong ngày

| Path | Nội dung |
|------|----------|
| `Nectar/Core/DevTools/NectarLog.swift` | Logger OSLog |
| `Nectar/Shared/Components/Skeleton/*` | Skeleton system |
| `Nectar/Features/Auth/**` | Login API |
| `docs/debugging-oslog-proxyman.md` | OSLog + Proxyman + BP |
| `docs/skeleton-loading.md` | Cách dùng skeleton |
| `docs/congviec_ngay.md` | File này |

---

## 4. Checklist tự ôn nhanh

- [ ] Giải thích vì sao không parse JSON trong `body` SwiftUI
- [ ] Viết 1 section Home với `.skeleton(isLoading:)`
- [ ] Filter Console bằng `Nectar log Network`
- [ ] Mô tả luồng login từ button → Keychain
- [ ] Cài Proxyman bắt 1 request `customer/login`
