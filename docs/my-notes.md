# Architecture của tôi — Nectar

## Tổng quan

Nectar là app SwiftUI học iOS banking, map từ kinh nghiệm React Native (PostPay). App dùng **feature-first Clean Architecture** với 3 lớp chính:

1. **Presentation** — `View` + `ViewModel` (`@MainActor`)
2. **Domain** — models (`BankAccount`, `Transaction`) + `protocol` Repository
3. **Data** — `Mock*Repository`, `APIAccountRepository`, `MockBankStore`

## Luồng dữ liệu

```
View → ViewModel.load()
         → AccountRepository / TransferRepository (protocol)
              → MockBankStore (in-memory) hoặc APIClient (HTTP)
```

View **không** gọi API trực tiếp — giống tách `api.ts` khỏi screen trong RN.

## Auth & session

- Onboarding flag → `UserDefaults`
- Access token → **Keychain** (`KeychainService`)
- Route gate → `AppSession.route` trong `RootView`
- Idle lock 5 phút → `SessionLockService` + overlay

## Transfer (core banking)

Flow 4 bước: **form → confirm → OTP → success**

- Validate: min 10.000 VND, đủ số dư, hạn mức
- Step-up: Face ID + OTP mock `123456`
- Side-effect: `MockBankStore.applyTransfer` trừ tiền + ghi lịch sử

## Vì sao `Decimal` cho tiền?

Tránh sai số floating-point của `Double` — chuẩn banking/fintech.

## Điểm mở rộng

- Nối PostPay API qua `APIClient` + envelope `API000`
- WidgetKit đọc số dư từ `WidgetDataStore`
- Deep link `nectar://transfer`
