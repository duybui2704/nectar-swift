# Architecture — Nectar (RN / Flutter mindset)

## So sánh lớp

| Layer | React Native (PostPay) | SwiftUI (`Nectar`) |
|-------|------------------------|------------------------------|
| UI | Screen components | `View` struct |
| State | Zustand / Context | `@MainActor` `ObservableObject` ViewModel |
| Domain | types + service contracts | `struct` models + `protocol` repository |
| Data | `api.ts` + store | `Mock*Repository` → `MockBankStore` (sau: `URLSession`) |
| DI | import module / ctor | Constructor defaults trên ViewModel |
| Navigation | React Navigation | `RootView` route + `NavigationStack` / `TabView` |
| Storage | MMKV / AsyncStorage | UserDefaults (flags) + **Keychain** (token) |
| Security | Biometrics lib | `LocalAuthentication` Face ID |

> Cũng map được với Flutter starter: Widget ≈ View, BLoC ≈ ViewModel — xem bảng cũ nếu bạn biết Flutter.

## Data flow

```
View  →  ViewModel.load() / submit()
            →  Repository protocol
                 →  MockRepository
                      →  MockBankStore / MockBankAPI
                         (tương lai: APIClient + URLSession)
```

## Status pattern (giống loading flags / BLoC status)

```swift
enum Status: Equatable {
  case idle, loading, success, failure(String)
}
```

Dùng trên Dashboard, History, Account detail, Cards, Transfer.

## Transfer side-effects (quan trọng)

`MockBankStore.applyTransfer`:

1. Validate amount / balance / hạn mức
2. Trừ số dư account nguồn
3. Prepend `Transaction` vào lịch sử
4. Trả `TransferResult.referenceId`

→ Home & History phản ánh đúng sau khi chuyển (vòng demo giống app thật).

## Vì sao hợp ứng tuyển ngân hàng?

1. Domain tiền tệ (`Decimal` + formatter VND) — tránh `Double` cho money
2. Transfer có **validation + confirm + Face ID + reference id**
3. Biometric auth — tiêu chuẩn mobile banking
4. Session token trong **Keychain**
5. Masked account numbers — privacy mindset
6. Parallel fetch (`async let`)
7. Clean folders — dễ giải thích trong interview

## Doc học chính cho RN

→ **[swiftui-for-react-native.md](./swiftui-for-react-native.md)**  
→ **[learning-path.md](./learning-path.md)** — lộ trình 3 tháng đầy đủ
