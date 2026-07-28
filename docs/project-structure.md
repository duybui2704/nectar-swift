# Cấu trúc dự án Nectar

Tài liệu giải thích **từng thư mục** trong app grocery SwiftUI, luồng chạy hiện tại, và quy ước khi thêm code mới.

---

## 1. Big picture

```
NectarSwiftUI/
├── Nectar/                      # App target chính
├── NectarTests/                 # Unit tests
├── NectarWidgetExtension/       # Widget (độc lập, chưa nối catalog grocery)
├── docs/                        # Tài liệu nội bộ
├── Info.plist
└── Nectar.xcodeproj/
```

**Luồng màn hình sống:**

```
NectarApp
  └─ RootView (+ AppSession)
        ├─ SplashView
        ├─ OnboardingView
        ├─ LoginView
        └─ MainShellView
              ├─ ShopView      (Home — banners + rails)
              ├─ ExploreView
              ├─ CartView
              ├─ FavouriteView
              └─ ProfileView
```

---

## 2. `Nectar/` — từng thư mục

### `App/`
**Vai trò:** điểm vào app + session + routing gốc.

| File | Việc làm |
|------|----------|
| `NectarApp.swift` | `@main`, inject `AppSession`, cấu hình HotReload + URLCache |
| `RootView.swift` | Switch theo `AppSession.route` (splash → onboarding/login/main) |
| `AppSession.swift` | Auth/onboarding state, gọi `AppBootstrap.prefetchLaunchAPIs()` nền lúc splash |

Không đặt UI feature dài ở đây.

---

### `Core/`
**Vai trò:** hạ tầng dùng chung — **không** phụ thuộc một màn Shop/Cart cụ thể.

#### `Core/DesignSystem/`
Token UI: màu (`NectarColors`), typography (`NectarTypography`), scale/spacing (`NectarMetrics`), helper `.screenPadding()`.

#### `Core/Network/`
HTTP + identity + prefetch:

| File | Việc làm |
|------|----------|
| `APIConfig.swift` | Host từng service, path endpoint, envelope `{ status, result }` |
| `APIClient.swift` | `actor` URLSession — GET/POST, retry, log |
| `PrintervalAPI.swift` | Facade từng endpoint (có thể có hàm chưa bind UI) |
| `AppBootstrap.swift` | Prefetch **song song** lúc launch / vào Shop — **chỉ gọi API đang dùng** |
| `AppIdentity.swift` | `token` / `deviceId` / country |
| `NetworkLogger.swift` | Log request/response (DEBUG) |
| `DeviceInfo.swift` | User-Agent |
| `LocalizationModels.swift` + `LocalizationStore.swift` | Decode + cache `/localization` |
| `LocationResult.swift` | Decode `/location` (geo — khác localization) |
| `MockNectarAPI.swift` | Tên/SĐT demo + `delay` cho Login |

#### `Core/Storage/`
`AppStorageService` (UserDefaults flags) + `KeychainService` (token).

#### `Core/Security/`
`BiometricAuthService` — Face ID / Touch ID (Profile toggle).

#### `Core/Errors/`
`AppError` — lỗi domain dùng chung.

#### `Core/DevTools/`
`HotReload.swift` — Inject/InjectionNext, chỉ DEBUG. Launch arg `-DISABLE_HOT_RELOAD` khi debug crash.

---

### `Features/`
**Vai trò:** từng **feature vertical** — UI + (khi cần) Data/Domain của feature đó.

Quy ước thư mục trong 1 feature:

```
Features/<Name>/
├── Domain/          # Model thuần (struct), không import SwiftUI nếu có thể
├── Data/            # Mapper, store, repository của feature
└── Presentation/    # View + ViewModel + Components/
```

#### Features đang **live**

| Feature | Ý nghĩa |
|---------|---------|
| `Splash/` | Màn chờ mở app |
| `Onboarding/` | Intro lần đầu |
| `Auth/` | Login |
| **`Shop/`** | **Home grocery** — banner, Exclusive Offer, Best Selling |
| `Explore/` | Tab khám phá (stub UI) |
| `Cart/` | Tab giỏ (stub) |
| `Favourite/` | Tab yêu thích (stub) |
| `Profile/` | Account / settings |

#### `Features/Shop/` chi tiết

```
Shop/
└── Presentation/
    ├── ShopView.swift
    ├── ShopViewModel.swift
    └── Components/
        ├── HomeBannerCarousel.swift
        ├── HomeSectionHeader.swift
        ├── ProductCardView.swift
        └── ProductHorizontalRail.swift
```

Model / mapper / cache Home nằm ở **`Core/Home/`** (dùng chung với `AppBootstrap`, tránh Core phụ thuộc Features):

```
Core/Home/
├── HomeModels.swift        # HomeBanner, ShopProduct, HomeMockData
├── HomeDTOMapper.swift     # JSON → domain
└── HomeCatalogStore.swift  # cache banners / rails
```

Map API → UI:

| API | UI |
|-----|-----|
| `home/get-banners` | Carousel |
| `today-big-deals` | Exclusive Offer |
| `recommendation/products` | Best Selling |
| `localization` | Region / currency symbol |
| `location` | Header geo (nếu có) |

---

### `Shared/`
**Vai trò:** UI / shell dùng **nhiều feature**, không thuộc 1 feature.

#### `Shared/Shell/`
| File | Việc làm |
|------|----------|
| `MainShellView.swift` | Custom tab shell; **giữ sống** mọi tab (opacity) |
| `FloatingTabBar.swift` | Tab bar nổi glass |
| `TabBarVisibility.swift` | Ẩn/hiện khi scroll |
| `ScrollOffsetTracker.swift` | KVO contentOffset → tab bar |

#### `Shared/Components/`
| File | Việc làm |
|------|----------|
| `RemoteImageView.swift` | `AsyncImage` + bootstrap URLCache |
| `EmptyStateView.swift` | Empty + StatusBanner |
| `PlaceholderFeatureView.swift` | Màn tạm (Profile NavigationLink) |

---

### `Resources/`
Assets.xcassets (logo, onboarding, …).

### `Preview Content/`
Asset / data chỉ cho Canvas Preview.

---

## 3. Performance — đã xử lý / cần nhớ

| Vấn đề cũ | Cách xử lý |
|-----------|------------|
| `.id(selectedTab)` destroy cả tab | `MainShellView` giữ 5 tab, `opacity` + `allowsHitTesting` |
| `TabView` page trong `ScrollView` dọc | Banner dùng `ScrollView(.horizontal)` + `.scrollTargetBehavior(.paging)` |
| Gọi 9+ API rồi bỏ data | `AppBootstrap` chỉ gọi endpoint bind UI |
| Ảnh tải lại mỗi lần | `URLCache` 64MB mem / 256MB disk lúc launch |
| Mock ghi đè cache API | Mock chỉ hiển thị UI; store chỉ nhận data API thật |
| Banking leftovers compile vào binary | Đã xoá Offers/Cards/History/Transfers/Accounts/Dashboard… |

**Lưu ý:** Hot reload (Inject) có thể `EXC_BAD_ACCESS` — tắt InjectionNext hoặc `-DISABLE_HOT_RELOAD` khi debug memory/crash.

---

## 4. Quy tắc thêm code mới

1. **UI 1 màn** → `Features/<X>/Presentation/`
2. **Model của feature** → `Features/<X>/Domain/`
3. **Decode/API map của feature** → `Features/<X>/Data/`
4. **HTTP chung** → `Core/Network/PrintervalAPI` + endpoint trong `APIConfig`
5. **Prefetch** → thêm vào `AppBootstrap` **chỉ khi** đã decode + bind UI
6. **Component dùng ≥ 2 feature** → `Shared/Components/`
7. **Không** để View gọi `APIClient` trực tiếp — qua ViewModel / Bootstrap / Store

---

## 5. Docs liên quan

- [api-flow.md](./api-flow.md) — luồng API chi tiết  
- [hot-reload.md](./hot-reload.md) — InjectionNext  
- [architecture.md](./architecture.md) — so sánh mindset RN/Flutter (một phần đã cũ sau khi bỏ banking)

---

## 6. Đã dọn (cleanup snapshot)

Đã xoá các module banking không còn route:

- `Features/Offers`, `Cards`, `History`, `Transfers`, `Accounts`, `Dashboard`
- `MainTabView` (wrapper thừa)
- `SessionLock*`, `PINService`, `OTPInputView`, `WidgetDataStore`
- `MockNectarStore`, `MoneyFormatter`, `TransferConstants`
- `TransferViewModelTests`

Giữ: `BiometricAuthService`, `MockNectarAPI` (Login/Profile), Shop stack, Shell tab bar.
