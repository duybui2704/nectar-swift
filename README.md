# Nectar

App **SwiftUI** grocery / commerce starter (tên project: **Nectar**) — học iOS từ React Native.

| React Native | Nectar Starter |
|--------------|-------------------|
| Screen + Zustand | View + `@MainActor` ViewModel |
| `api.ts` | Repository + `APIClient` |
| MMKV token | **Keychain** |
| React Navigation | `MainShellView` + deep links |

---

## Chạy project

```bash
open Nectar.xcodeproj
```

**Demo:** `demo` / `123456` · OTP: `123456` · PIN lock: `000000`  
**Deep link:** `nectar://transfer`

**Hot Reload (Fast Refresh):** đã cấu hình sẵn — xem [`docs/hot-reload.md`](docs/hot-reload.md) để cài **InjectionNext** + SPM `Inject`, save file → simulator update ngay.

---

## Tính năng (3 tháng roadmap — đã implement)

### Tháng 1 — Foundation
- Splash → Onboarding → Login (Face ID) → Tabs
- Tab **Ưu đãi**, Home wallet card, History, Transfer, Cards, Profile
- Transfer 4 bước: form → confirm → **OTP** → success
- Min amount 10.000 VND · balance side-effect sau transfer

### Tháng 2 — Production mindset
- `APIClient` URLSession + JWT refresh hooks
- `APIAccountRepository` (JSONPlaceholder demo)
- Unit tests `TransferViewModelTests`
- Session idle lock 5 phút + PIN fallback
- `WalletCardView` tách subview (perf)

### Tháng 3 — Mastery
- `@Observable` HistoryViewModel
- Deep link `nectar://transfer`
- WidgetKit extension (`NectarWidgetExtension`)
- System design + mock interview docs

---

## Architecture

```
View → ViewModel → Repository → MockBankStore / APIClient
```

Session token: **Keychain** · Flags: UserDefaults

---

## Docs học (theo thứ tự)

**Bài giảng chính (đọc trước tiên):**
1. [docs/level-1-foundation.md](docs/level-1-foundation.md) — Swift, View, Property Wrapper, MVVM, Perf cơ bản
2. [docs/level-2-advanced.md](docs/level-2-advanced.md) — TCA/Observable, Combine, Animation, Network, MapKit, Security

**Dev workflow:**
- [docs/hot-reload.md](docs/hot-reload.md) — cấu hình Fast Refresh với InjectionNext + Inject SPM

**Tài liệu bổ sung:**
3. [docs/swiftui-for-react-native.md](docs/swiftui-for-react-native.md) — map RN ↔ SwiftUI
4. [docs/learning-path.md](docs/learning-path.md) — lộ trình 3 tháng
5. [docs/state-notes.md](docs/state-notes.md) — Tuần 1
6. [docs/my-notes.md](docs/my-notes.md) — architecture tóm tắt
7. [docs/system-design-mobile-banking.md](docs/system-design-mobile-banking.md)
8. [docs/security-checklist.md](docs/security-checklist.md)
9. [docs/instruments-notes.md](docs/instruments-notes.md)
10. [docs/mock-interview-guide.md](docs/mock-interview-guide.md)
11. [docs/banking-interview.md](docs/banking-interview.md)

---

## Portfolio checklist

- [ ] Screenshot: Login, Home, Transfer OTP, History, Profile
- [ ] Video demo 3–5 phút (script trong mock-interview-guide)
- [ ] Push GitHub + README EN

---

## Test

```bash
xcodebuild test -scheme Nectar -destination 'generic/platform=iOS Simulator'
```

---

## Widget extension

Thêm target `NectarWidgetExtension` trong Xcode (file sẵn tại `NectarWidgetExtension/BalanceWidget.swift`).  
Bật App Group `group.com.example.Nectar` cho app + widget.
