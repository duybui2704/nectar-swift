# Skeleton loading — Nectar

Hệ skeleton shimmer dùng chung toàn app. Áp **từng section** độc lập (banner / rail / category…), không bắt buộc full-screen spinner.

---

## 0. File

| File | Vai trò |
|------|---------|
| `Shared/Components/Skeleton/SkeletonStyle.swift` | Màu + tốc độ shimmer |
| `Shared/Components/Skeleton/SkeletonShimmer.swift` | Phase sync + overlay |
| `Shared/Components/Skeleton/SkeletonBone.swift` | Xương: rect / circle / line |
| `Shared/Components/Skeleton/SkeletonGate.swift` | API `.skeleton(isLoading:)` |
| `Shared/Components/Skeleton/SkeletonLayout.swift` | Preset theo bố cục Home |

---

## 1. Cách dùng nhanh

### A. Modifier trên view có sẵn

```swift
HomeBannerCarousel(banners: viewModel.banners)
    .skeleton(isLoading: viewModel.showBannersSkeleton) {
        SkeletonLayout.banner()
    }
```

Khi `isLoading == true` → hiện skeleton; `false` → hiện content.

### B. `SkeletonGate` (content optional / Group)

```swift
SkeletonGate(isLoading: viewModel.showEventBoxSkeleton) {
    if let event = viewModel.eventBox.first {
        EventBoxView(event: event, currencySymbol: "$")
    }
} skeleton: {
    SkeletonLayout.eventBanner()
}
```

### C. Flag từng phần (khuyến nghị)

Trong ViewModel:

```swift
var showBannersSkeleton: Bool { isLoadingHome && banners.isEmpty }
var showExclusiveSkeleton: Bool { isLoadingHome && exclusiveOffers.isEmpty }
```

→ Section đã có cache **không** flash skeleton; section chưa data mới hiện xương.

Shop Home đã wire sẵn theo pattern này (`ShopView` + `ShopViewModel`).

---

## 2. Preset layout

| API | Khớp UI |
|-----|---------|
| `SkeletonLayout.banner()` | `HomeBannerCarousel` (~140) |
| `SkeletonLayout.categoryRail()` | `CategoryList` |
| `SkeletonLayout.productCard()` | `ProductCardView` 173×230 |
| `SkeletonLayout.productRail(title:count:)` | `ProductHorizontalRail` |
| `SkeletonLayout.reelsRail()` | `ProductReelsRail` |
| `SkeletonLayout.sellerSpotlight()` | `SellerSpotlight` |
| `SkeletonLayout.eventBanner()` | Event box + rail |
| `SkeletonLayout.sectionHeader()` | Title + See all |
| `SkeletonLayout.textBlock(lines:)` | PDP / text |
| `SkeletonLayout.avatarRow()` | List cell |

---

## 3. Tự ghép layout mới

```swift
SkeletonScope {
    VStack(alignment: .leading, spacing: 12) {
        SkeletonBone.rect(height: 160.scaled, cornerRadius: 12)
        SkeletonBone.line(height: 16, widthFactor: 0.7)
        HStack(spacing: 12) {
            SkeletonBone.circle(size: 40.scaled)
            SkeletonBone.line(height: 12, widthFactor: 0.5)
        }
    }
    .screenPadding()
}
```

`SkeletonScope` = bắt buộc nếu tự build (để shimmer chạy + sync).  
Preset trong `SkeletonLayout` đã bọc scope qua `.skeleton` / `SkeletonGate`.

---

## 4. Quy ước

1. **Skeleton theo section**, không che cả `ScrollView` trừ khi màn thật sự blank.
2. Điều kiện: `isLoading && data.isEmpty` — tránh che content đã cache.
3. Size xương ≈ size UI thật (dùng `.scaled` / `NectarMetrics`).
4. Đừng dùng `ProgressView` hàng loạt trên Home; skeleton nhẹ hơn.

---

## 5. Tuỳ chỉnh style

`SkeletonStyle.swift`:

- `base` / `highlight` — màu xương & vệt sáng  
- `animationDuration` — mặc định `1.35s`
