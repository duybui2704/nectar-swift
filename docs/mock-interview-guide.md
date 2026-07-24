# Mock Interview Guide — 3 vòng (Tuần 12)

## Vòng 1: Architecture (10 phút)

1. Mô tả layer View / ViewModel / Repository / Store
2. Vì sao protocol Repository?
3. `@StateObject` vs `@EnvironmentObject` — ví dụ `DashboardView`
4. `async let` dùng ở đâu?

**Tài liệu:** [my-notes.md](./my-notes.md), [architecture.md](./architecture.md)

## Vòng 2: Coding / SwiftUI (10 phút)

1. Thêm validation min amount — chỉ ra `TransferViewModel.validateForm`
2. Giải thích transfer 4 bước
3. Fix bug: double submit → `isSubmitting`
4. `@Observable` vs `ObservableObject` — `HistoryViewModelObservable`

## Vòng 3: Banking domain (10 phút)

1. Token lưu đâu? Vì sao không UserDefaults?
2. Transfer idempotency + reference id
3. Offline transfer strategy (xem [system-design-mobile-banking.md](./system-design-mobile-banking.md))
4. OTP + Face ID — step-up auth

**Flashcard:** [banking-interview.md](./banking-interview.md)

## Video demo script (3–5 phút)

1. Splash → Onboarding (skip nếu đã xong)
2. Login `demo` / `123456`
3. Home — ẩn/hiện số dư
4. Chuyển 50.000 → OTP `123456` → Face ID → success
5. History — thấy giao dịch mới
6. (Optional) Deep link: `nectar://transfer` trong Simulator

## Portfolio README checklist

- [ ] 5 screenshots
- [ ] Architecture diagram (mermaid)
- [ ] Tech: SwiftUI, MVVM, Keychain, LocalAuthentication, WidgetKit
- [ ] Link repo GitHub
