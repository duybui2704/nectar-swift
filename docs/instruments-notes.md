# Instruments & Performance Notes

## SwiftUI profiling (Tuần 5)

1. Xcode → Product → Profile (`⌘I`)
2. Chọn **Swift UI** hoặc **Time Profiler**
3. Thao tác: scroll History 50 items, pull-to-refresh Home

## Đã tối ưu trong repo

| Area | Change |
|------|--------|
| Dashboard | Tách `WalletCardView` — giảm body recompute |
| History | `List` + `Identifiable` transactions |
| Account detail | `LazyVStack` thay `ForEach` trong `ScrollView` |
| ViewModel | `@Published private(set)` — chỉ publish cần thiết |

## Red flags cần tránh

- `ObservableObject` recreate do dùng `@ObservedObject` + `= VM()` trong body
- Heavy work trong `body` (formatting loop lớn)
- `List` inside `ScrollView` (double scroll)

## Benchmark ghi chú

Ghi lại trước/sau khi tách `WalletCardView`:

- Time Profiler: `Body` update count khi toggle ẩn số dư
- Mục tiêu: không spike frame > 16ms khi scroll History

## Công cụ khác

- **Memory Graph** — leak `ViewModel` retain cycle
- **Network Link Conditioner** — test timeout APIClient
