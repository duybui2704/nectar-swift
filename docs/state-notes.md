# SwiftUI State — Ghi chú Tuần 1

## `@State` — local UI (≈ `useState`)

Dùng trên **View** cho state nhẹ, thuộc riêng màn đó.

```swift
@State private var balanceHidden = false
```

Ví dụ: [DashboardView.swift](../Nectar/Features/Dashboard/Presentation/DashboardView.swift) — toggle ẩn/hiện số dư.

## `@StateObject` — sở hữu ViewModel (≈ store tạo 1 lần khi mount)

View **tạo** ViewModel → dùng `@StateObject` để không bị recreate mỗi lần body render.

```swift
@StateObject private var viewModel = DashboardViewModel()
```

**Quy tắc:** ai gọi `= ViewModel()` thì dùng `@StateObject`.

## `@EnvironmentObject` — session toàn app (≈ Context / Zustand auth)

Inject từ root:

```swift
// NectarApp.swift
.environmentObject(session)

// DashboardView.swift
@EnvironmentObject private var session: AppSession
```

`AppSession` giữ route splash/login/main — giống auth gate PostPay.

## `@Observable` + `@State` (iOS 17+, Tuần 11)

Thay `ObservableObject` + `@Published`:

```swift
@State private var viewModel = HistoryViewModelObservable()
```

Xem [HistoryViewModelObservable.swift](../Nectar/Features/History/Presentation/HistoryViewModelObservable.swift).

## Checkpoint Tuần 1

- [ ] Giải thích được 3 loại state trên Dashboard
- [ ] Đã thêm tab Ưu đãi
- [ ] Đã chạy app `⌘R` thành công
