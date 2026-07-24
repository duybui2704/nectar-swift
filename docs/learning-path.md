# Lộ trình học 3 tháng (React Native → SwiftUI Banking)

~3+ giờ/ngày · Dự án: **Nectar**

| Tháng | Mục tiêu | Doc chính |
|-------|----------|-----------|
| 1 | Nắm chắc cơ bản | [**level-1-foundation.md**](./level-1-foundation.md), [state-notes.md](./state-notes.md), [swiftui-for-react-native.md](./swiftui-for-react-native.md) |
| 2 | Tối ưu & production | [**level-2-advanced.md**](./level-2-advanced.md), [instruments-notes.md](./instruments-notes.md), [security-checklist.md](./security-checklist.md) |
| 3 | Thành thạo + phỏng vấn | [system-design-mobile-banking.md](./system-design-mobile-banking.md), [mock-interview-guide.md](./mock-interview-guide.md) |

> 📚 **Bài giảng chính (intern-friendly):**
> - [Level 1 — Nền tảng](./level-1-foundation.md) — Swift, View, Property Wrapper, MVVM, Perf cơ bản
> - [Level 2 — Nâng cao](./level-2-advanced.md) — TCA/Observable, Combine, Animation, Network, MapKit, Security

---

## Tháng 1 — Foundation

### Tuần 1 — SwiftUI + State
- [ ] Đọc [state-notes.md](./state-notes.md)
- [ ] Tab **Ưu đãi** đã có trong app
- [ ] Giải thích `@State` / `@StateObject` / `@EnvironmentObject`

### Tuần 2 — Architecture
- [ ] Đọc [architecture.md](./architecture.md)
- [ ] Chạy vòng transfer → balance + history cập nhật
- [ ] Min amount 10.000 VND trong `TransferConstants`

### Tuần 3 — Security
- [ ] Keychain + Face ID + OTP flow
- [ ] [security-checklist.md](./security-checklist.md)
- [ ] [banking-interview.md](./banking-interview.md) — 5 câu đầu

### Tuần 4 — Consolidation
- [ ] Account detail + refresh + error banner
- [ ] [my-notes.md](./my-notes.md)
- [ ] Mock interview 15 phút

---

## Tháng 2 — Tối ưu & Production

### Tuần 5 — Performance
- [ ] [instruments-notes.md](./instruments-notes.md)
- [ ] `WalletCardView` tách subview

### Tuần 6 — Networking
- [ ] `APIClient` + `APIAccountRepository`
- [ ] JWT refresh concept trong APIClient

### Tuần 7 — Tests
- [ ] `NectarTests` — chạy `⌘U`
- [ ] Idempotency `isSubmitting` trên transfer

### Tuần 8 — Security hardening
- [ ] Session lock overlay
- [ ] PIN fallback

---

## Tháng 3 — Mastery

### Tuần 9 — Advanced features
- [ ] OTP 4-step transfer
- [ ] Deep link `nectar://transfer`
- [ ] WidgetKit extension

### Tuần 10 — System design
- [ ] [system-design-mobile-banking.md](./system-design-mobile-banking.md)
- [ ] Trình bày 20 phút

### Tuần 11 — Modern SwiftUI
- [ ] `HistoryViewModelObservable` (`@Observable`)
- [ ] Code review toàn repo

### Tuần 12 — Portfolio
- [ ] [mock-interview-guide.md](./mock-interview-guide.md)
- [ ] README portfolio + video demo

---

## Credential demo

- User: `demo` / Pass: `123456`
- OTP: `123456` / PIN lock: `000000`
- Deep link: `nectar://transfer`
