# Product Reels — đọc code & hiểu luồng SwiftUI

Tài liệu cho phần **Reels** trên Home (`ShopView`): từ API → model → ViewModel → rail ngang → fullscreen dọc.

Đọc theo thứ tự section **3 → 6** nếu muốn đi từ data vào UI; đọc **7** nếu muốn hiểu “SwiftUI nghĩ gì” khi render.

---

## 1. Mục tiêu UI

| Lớp | Hành vi |
|-----|---------|
| **Rail** (dưới banner) | Scroll ngang, card 9:16, **thumbnail** + icon play (không autoplay video) |
| **Fullscreen** (tap card) | Feed dọc paging, mở đúng reel đã tap, mute/unmute, tap pause/play, nút X đóng |

Tham chiếu UX: Facebook / Instagram Reels tray + viewer.

---

## 2. File liên quan (map nhanh)

```
API / data (MVVM)
  APIConfig.swift / PrintervalAPI.swift     → product-video/find (www)
  Features/Shop/Data/HomeRepository.swift   → loadHomeCatalog (gồm reels)
  Features/Shop/Data/HomeDTOMapper.swift    → productReels(from:)
  Features/Shop/Domain/Models/ShopModels.swift → ProductReel
  Features/Shop/Data/HomeCatalogStore.swift → cache productReels

UI
  ShopView.swift               → ProductReelsRail dưới banner
  ShopViewModel.swift          → @Published productReels (via HomeCatalogProviding)
  ProductReelsRail.swift       → strip ngang (thumbnail only) + fullScreenCover
  ProductReelsFullscreenView.swift → viewer dọc; AVPlayer chỉ khi page active
```

**Quy ước:** Presentation không gọi `URLSession`. ViewModel → `HomeCatalogProviding` → Repository.

**Perf:** rail không dùng `AVPlayer` — xem [`performance-memory.md`](./performance-memory.md).

---

## 3. Luồng data (end-to-end)

```
ShopView
  .task { await viewModel.loadHome() }
        │
        ▼
ShopViewModel.loadHome()
  • catalog.cachedCatalog() → apply (hiện ngay nếu có)
  • lần đầu → catalog.loadHomeCatalog()  // HomeRepository
        │
        ▼
HomeRepository
  big-deals → rồi TaskGroup (recommendations, categories,
              recently-viewed, event-box, product-video)
        │
        ▼
PrintervalAPI.fetchProductVideos() → Data
HomeDTOMapper.productReels → [ProductReel] → Store + HomeCatalog
        │
        ▼
ShopView → ProductReelsRail(reels: viewModel.productReels)
```

### Cách đọc từng bước trong code

1. **UI entry:** `ShopView` — tìm `ProductReelsRail`.
2. **State:** `ShopViewModel` — `@Published productReels`, gán trong `apply(_:)`.
3. **Repository:** `HomeRepository.loadHomeCatalog` — TaskGroup gồm `productVideoFind`.
4. **HTTP:** `PrintervalAPI.fetchProductVideos` → `APIClient.getData(..., service: .www)`.
5. **Decode:** `HomeDTOMapper.productReels` — JSON linh hoạt (`image_url`, `src`, nested `product`).

Prefetch home **1 lần / session** (`HomeRepository.didLoadHome` + flag request trên VM).

---

## 4. Model `ProductReel`

```swift
struct ProductReel: Identifiable, Hashable, Sendable {
    let id: Int              // id video — dùng cho ForEach + scrollPosition + fullScreenCover
    let thumbnailURL: URL?
    let videoURL: URL?       // field API `src`
    let productId: Int
    let productName: String
    let displayPrice: String // vd. "$12.95"
    let productImageURL: URL?
}
```

**Vì sao `Identifiable`?**  
SwiftUI `ForEach(reels)` và `.fullScreenCover(item:)` cần `id` ổn định để diff view / present sheet.

**Vì sao mapper linh hoạt (dictionary) thay vì Codable cứng?**  
API product có thể đổi key; cùng pattern với recommendation / big-deals trong `HomeDTOMapper`.

---

## 5. Rail ngang — `ProductReelsRail`

### Cây view (đọc từ ngoài vào)

```
ProductReelsRail
├─ HomeSectionHeader("Reels")
├─ ScrollView(.horizontal)
│     └─ LazyHStack
│           └─ ForEach → Button → ProductReelCardView
└─ .fullScreenCover(item: $selectedReel) → ProductReelsFullscreenView
```

### State quan trọng

| Symbol | Loại | Ý nghĩa |
|--------|------|---------|
| `reels` | `let` (input) | Data từ ViewModel — **source of truth** phía parent |
| `selectedReel` | `@State` | `nil` = đóng; có value = mở fullscreen đúng item đó |

```swift
Button {
    selectedReel = reel          // gán → SwiftUI present fullScreenCover
} label: {
    ProductReelCardView(reel: reel)
}
.fullScreenCover(item: $selectedReel) { reel in
    ProductReelsFullscreenView(reels: reels, initialID: reel.id)
}
```

**Cách đọc SwiftUI ở đây:**

- `let reels` = props (như React props) — parent đẩy xuống.
- `@State selectedReel` = state **local** của rail — chỉ rail cần biết “đang mở reel nào”.
- Gán `selectedReel = reel` không “navigate bằng router”; modifier `.fullScreenCover(item:)` **observe** binding và tự present/dismiss khi `Optional` đổi.

### Card + video muted

`ProductReelCardView` → `ReelMutedVideoView`:

- Thumbnail (`RemoteImageView`) làm nền ngay.
- `AVPlayer` muted, loop khi `onAppear`; `pause` khi `onDisappear`.
- `LazyHStack` chỉ materialize card gần viewport → đỡ tạo nhiều player cùng lúc.

Player model (`ReelPlayerModel`) là `ObservableObject` + `@StateObject` — sống theo lifetime của **một card**, không phải cả rail.

---

## 6. Fullscreen — `ProductReelsFullscreenView`

### Cây view

```
ProductReelsFullscreenView
├─ ScrollView(.vertical) + paging
│     └─ LazyVStack
│           └─ ForEach → FullscreenReelPage (cao = 1 màn hình)
├─ topChrome (X + mute)
└─ currentID (@State) ↔ .scrollPosition(id:)
```

### Paging dọc (iOS 17)

| Modifier | Việc làm |
|----------|----------|
| `.containerRelativeFrame(.vertical)` | Mỗi page cao đúng viewport |
| `.scrollTargetLayout()` + `.scrollTargetBehavior(.paging)` | Snap từng reel |
| `.scrollPosition(id: $currentID)` | Sync id reel đang xem |
| `initialID` trong `init` | Mở đúng video vừa tap trên rail |

### Chỉ play reel đang active

```swift
FullscreenReelPage(..., isActive: currentID == reel.id, isMuted: isMuted)
```

- `isActive == true` → `play()`
- `isActive == false` / `onDisappear` → `pause()`

Tránh N video cùng play khi LazyVStack giữ vài page lân cận.

### Gesture / chrome

| Tương tác | Cơ chế |
|-----------|--------|
| Đóng | `dismiss()` từ `@Environment(\.dismiss)` |
| Mute | `@State isMuted` đẩy xuống mọi page |
| Pause/play | `onTapGesture` → `model.togglePlay()` |

---

## 7. Cách “đọc” SwiftUI (checklist khi mở file)

Khi mở một file View, hỏi lần lượt:

1. **Input là gì?** `let` / props từ parent (`reels`, `reel`, `currencySymbol`).
2. **State local là gì?** `@State`, `@StateObject`, `@FocusState` — thứ đổi khi user tương tác.
3. **Side effect ở đâu?** `.task`, `.onAppear`, `.onChange`, `.onDisappear` — chỗ gọi API / play video / cleanup.
4. **Presentation?** `.sheet` / `.fullScreenCover` / `NavigationLink` — đừng tìm “router” riêng.
5. **List thế nào?** `ForEach` + `Identifiable` — `id` phải ổn định.
6. **Ai owns data?** ViewModel / Store publish → View chỉ bind. Không decode JSON trong `body`.

### So sánh nhanh với React Native (nếu quen RN)

| RN | SwiftUI (Reels) |
|----|-----------------|
| `props.reels` | `let reels: [ProductReel]` |
| `useState(selected)` | `@State private var selectedReel` |
| `Modal visible={!!selected}` | `.fullScreenCover(item: $selectedReel)` |
| `FlatList horizontal` | `ScrollView` + `LazyHStack` |
| `useEffect` play/pause | `.onAppear` / `.onDisappear` / `.onChange` |
| Redux/store | `ShopViewModel` + `HomeCatalogStore` |

`body` **không** phải hàm render imperative — nó là **mô tả** UI theo state hiện tại; SwiftUI diff và cập nhật.

---

## 8. API reference

```http
GET https://printerval.com/product-video/find?page_size=10&page_id=0
Accept: application/json
User-Agent: PrintervalApp/IOS/...
```

Envelope:

```json
{
  "status": "successful",
  "result": [
    {
      "id": 903316,
      "image_url": "https://.../thumbnail.png",
      "src": "https://.../video.mp4",
      "product_id": 232392546,
      "product": {
        "id": 232392546,
        "name": "...",
        "display_price": "$12.95",
        "image_url": "https://..."
      }
    }
  ],
  "meta": { "has_next": true, "page_id": 0, "page_size": 10 }
}
```

Trong app:

- Host: `APIService.www` → `https://printerval.com`
- Path: `APIEndpoint.productVideoFind` → `product-video/find`
- Query mặc định: `page_size=10`, `page_id=0` (optional `from_id` trên facade nếu cần cursor)

---

## 9. Mở rộng an toàn

| Muốn thêm | Nên sửa |
|-----------|---------|
| Load page tiếp (infinite) | ViewModel + `fetchProductVideos(pageId:fromId:)` — không fetch trong `body` |
| Tap “See all” | `onSeeAll` trên `ProductReelsRail` / header |
| Mở PDP sản phẩm | callback từ overlay fullscreen → navigate Shop |
| Analytics impression | `.onChange(of: currentID)` trong fullscreen |
| Tắt autoplay rail (tiết kiệm data) | chỉ hiện thumbnail trên card, play khi fullscreen |

---

## 10. Debug nhanh

1. Console có `🎬 product reels: N` sau prefetch? → decode OK.
2. Rail trống nhưng log > 0? → `ShopView` có truyền `viewModel.productReels` không.
3. Fullscreen đen, không video? → check `videoURL` / ATS / URL `src`.
4. Mở sai video? → `initialID` + `.id(reel.id)` + `scrollPosition`.
5. Nhiều audio cùng lúc? → đảm bảo `isActive` pause page không focal.

---

## Liên kết

- Luồng API tổng: [`api-flow.md`](./api-flow.md)
- Cấu trúc thư mục: [`project-structure.md`](./project-structure.md)
- SwiftUI nếu quen RN: [`swiftui-for-react-native.md`](./swiftui-for-react-native.md)
