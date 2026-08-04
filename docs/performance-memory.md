# Performance & Memory — Home / Reels

Tài liệu giải thích **vì sao** cần tối ưu, **đã làm gì** trong Nectar, và **các bẫy** dễ gặp khi làm feed / video / list SwiftUI.

---

## 1. Vì sao cần tối ưu?

Home (`ShopView`) là màn “nặng” theo thiết kế:

| Thành phần | Chi phí nếu làm ẩu |
|------------|-------------------|
| Nhiều rail ngang + banner | Nhiều ảnh decode cùng lúc |
| Reels | `AVPlayer` = CPU decode + RAM buffer + mạng |
| Title rainbow `TimelineView` | Re-render liên tục dù user không tương tác |
| Prefetch API | Bão request → timeout / 403 / pin main gián tiếp |

Trên thiết bị yếu hoặc khi scroll nhanh, triệu chứng điển hình:

- Scroll giật (main thread bận decode / layout)
- RAM tăng → jetsam (iOS kill app)
- Nóng máy / hao pin
- Video “kẹt” hoặc nhiều audio cùng lúc

**Nguyên tắc:** trả phí nặng (video, decode lớn) **chỉ khi user đang xem**; Home chỉ giữ preview rẻ (thumbnail).

---

## 2. Đã tối ưu gì trong app?

### 2.1 Reels rail — không còn `AVPlayer` trên Home

**Trước:** mỗi card visible tạo `AVPlayer` + muted loop.  
Scroll ngang 4–6 card ≈ 4–6 decoder + buffer.

**Sau:** card chỉ `RemoteImageView(thumbnail)` + icon play.  
Video **chỉ** load trong `ProductReelsFullscreenView`.

**UX:** vẫn giống Facebook tray (ảnh cover + play); motion nằm ở fullscreen — đúng chỗ user chủ đích xem.

File: `ProductReelsRail.swift`

### 2.2 Fullscreen — một page active giữ item

**Trước:** `onAppear` gắn video kể cả page lân cận; `pause` nhưng **giữ** `AVPlayerItem` → buffer còn trong RAM.

**Sau:**

- `isActive == true` → `activate` (attach + play)
- `isActive == false` / `onDisappear` → `deactivate` = pause + `replaceCurrentItem(nil)`
- Layer player chỉ mount khi `isActive`
- `preferredForwardBufferDuration = 2` — giới hạn buffer phía trước

File: `ProductReelsFullscreenView.swift`

### 2.3 Ảnh — bớt spinner trên card nhỏ

`RemoteImageView(showsLoadingIndicator:)` — rail / reel card tắt `ProgressView`.  
Tránh hàng chục vòng xoay + layout churn khi nhiều `AsyncImage` `.empty`.

`URLCache` vẫn cấu hình lúc launch (`ImageCacheBootstrap`) — disk/memory cache HTTP.

### 2.4 Brand title — hạ fps `TimelineView`

`1/30` → `1/12` giây; shadow nhẹ hơn.  
Shimmer vẫn mượt với mắt; CPU idle trên Home giảm rõ.

File: `ShopView.swift` (`ShopLocationHeader`)

### 2.5 Đã có sẵn (giữ nguyên — vẫn quan trọng)

| Kỹ thuật | Chỗ |
|----------|-----|
| `LazyVStack` / `LazyHStack` | Shop, rails, reels |
| Prefetch home 1 lần / session | `HomeRepository.didLoadHome` |
| Launch chỉ banners | `AppBootstrap` → `prefetchLaunchBanners` |
| Category chỉ root | `HomeDTOMapper.categoryTree` (`children: []`) |
| MVVM — View không fetch | `ShopViewModel` → `HomeCatalogProviding` |

---

## 3. Phương pháp suy nghĩ (checklist)

Khi thêm UI mới, hỏi theo thứ tự:

1. **Có thể lazy không?** `LazyHStack` / `LazyVStack` / paging — đừng tạo 50 player/view nặng ngay.
2. **Preview có cần media nặng không?** Thumbnail > video; placeholder > full decode.
3. **Lifecycle đã cleanup chưa?** `onDisappear` / mất focus → pause **và** nhả resource (`nil` item, cancel Task).
4. **Animation có cần 60fps không?** UI trang trí: 8–12fps thường đủ.
5. **List có Identifiable ổn định không?** `id` đổi → SwiftUI recreate → leak cảm giác “memory tăng”.
6. **API có bão không?** Prefetch có giới hạn; đừng fire 10 host cùng lúc lúc splash.

Đo bằng Instruments: **Time Profiler**, **Allocations**, **os_signpost** — đừng tối ưu “cảm giác” không số.

---

## 4. Trường hợp khác dễ bị…

### Video / Reels / Stories

| Bẫy | Hệ quả | Cách tránh |
|-----|--------|------------|
| Autoplay mọi cell trong list | N decoder, nóng máy | Chỉ play cell focal / fullscreen |
| Chỉ `pause`, không bỏ `AVPlayerItem` | RAM buffer còn | `replaceCurrentItem(nil)` khi inactive |
| Một `AVPlayer` shared + đổi URL lung tung | Glitch / race | Player theo page **hoặc** queue rõ ràng + cancel |
| Preload 10 video “cho mượt” | Spike mạng + RAM | Prefetch tối đa ±1 page |

### Ảnh / `AsyncImage`

| Bẫy | Hệ quả | Cách tránh |
|-----|--------|------------|
| Full-res vào thumbnail 100pt | Decode lớn, scroll giật | CDN resize / thumb URL nếu API có |
| ProgressView trên mọi ô | Jank layout | `showsLoadingIndicator: false` trên rail |
| Không URLCache | Tải lại mỗi lần vào màn | `ImageCacheBootstrap` lúc launch |

### List / Scroll SwiftUI

| Bẫy | Hệ quả | Cách tránh |
|-----|--------|------------|
| `VStack` + `ForEach` trong `ScrollView` (không Lazy) | Tạo hết view một lúc | `LazyVStack` |
| `GeometryReader` sâu trong mọi row | Layout đắt | Hạn chế; đo size ở ngoài nếu được |
| `@StateObject` player trong mọi row luôn attach | Giống Reels cũ | Attach theo `isActive` |

### Animation / TimelineView

| Bẫy | Hệ quả | Cách tránh |
|-----|--------|------------|
| `.animation(minimumInterval: 1/60)` mãi | CPU idle cao | 8–12fps cho hiệu ứng trang trí |
| Không pause khi off-screen | Tốn pin tab ẩn | `paused:` theo visibility nếu cần |

### Networking

| Bẫy | Hệ quả | Cách tránh |
|-----|--------|------------|
| Prefetch mọi endpoint lúc splash | Timeout / 403 | Chỉ endpoint bind UI; sequential/parallel có kiểm soát |
| Decode JSON cây category sâu trên main | Freeze | Root-only / background decode |
| Retry vô hạn khi timeout | Hàng đợi request | `maxTimeoutRetries = 0` (đã có) |

### Architecture (liên quan perf gián tiếp)

| Bẫy | Hệ quả | Cách tránh |
|-----|--------|------------|
| Gọi API trong `body` | Request spam khi re-render | `.task` / ViewModel |
| `@Published` lớn publish mỗi field lẻ không cần | Re-render cả Home | Snapshot / gom update có chủ đích |
| Giữ toàn bộ page_data event trong nhiều bản copy | RAM | Parse khi cần (EventBox đã parse lúc render rail) |

---

## 5. Map file nhanh

| Tối ưu | File |
|--------|------|
| Rail thumbnail-only | `Features/Shop/Presentation/Components/ProductReelsRail.swift` |
| Fullscreen activate/deactivate | `…/ProductReelsFullscreenView.swift` |
| Image spinner flag | `Shared/Components/RemoteImageView.swift` |
| Title fps | `Features/Shop/Presentation/ShopView.swift` |
| Prefetch / cache | `Features/Shop/Data/HomeRepository.swift` |
| Luồng Reels (chức năng) | [`product-reels.md`](./product-reels.md) |
| MVVM / API | [`api-flow.md`](./api-flow.md), [`project-structure.md`](./project-structure.md) |

---

## 6. Khi nào tối ưu thêm?

Làm tiếp nếu Instruments báo nóng:

1. CDN/thumb size cho product card & reel thumbnail  
2. Pause `TimelineView` khi `ShopView` không visible (tab khác)  
3. Prefetch video **chỉ** ±1 id quanh `currentID` (không attach sẵn)  
4. Thay `AsyncImage` bằng loader có downsample (`ImageIO`) nếu ảnh gốc rất lớn  

Không tối ưu sớm những chỗ chưa đo được — giữ code đơn giản trước.
