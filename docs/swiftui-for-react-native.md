# SwiftUI cho React Native Developer

Hướng dẫn học **Nectar** nếu bạn đã quen React Native (PostPay / Zustand / React Navigation / fetch).

Đọc theo thứ tự section. Mỗi phần map thẳng sang code trong repo.

---

## Mục lục

1. [Big picture — app chạy thế nào](#1-big-picture--app-chạy-thế-nào)
2. [Bảng map RN → SwiftUI](#2-bảng-map-rn--swiftui)
3. [Swift basics bạn cần trước UI](#3-swift-basics-bạn-cần-trước-ui)
4. [View = Component (nhưng là struct)](#4-view--component-nhưng-là-struct)
5. [State — useState / Zustand / Context](#5-state--usestate--zustand--context)
6. [Navigation — React Navigation → SwiftUI](#6-navigation--react-navigation--swiftui)
7. [Architecture & data flow](#7-architecture--data-flow)
8. [Async / networking](#8-async--networking)
9. [Đọc từng feature quan trọng](#9-đọc-từng-feature-quan-trọng)
10. [Design system](#10-design-system)
11. [Bảo mật: Keychain + Face ID](#11-bảo-mật-keychain--face-id)
12. [Debug & Xcode tips](#12-debug--xcode-tips)
13. [Checklist học (thực hành)](#13-checklist-học-thực-hành)
14. [Lỗi tư duy hay gặp khi từ RN sang](#14-lỗi-tư-duy-hay-gặp-khi-từ-rn-sang)

---

## 1. Big picture — app chạy thế nào

### Entry point

| React Native | SwiftUI (repo này) |
|--------------|--------------------|
| `index.js` → `App.tsx` | `NectarApp.swift` (`@main`) |

```swift
@main
struct NectarApp: App {
    @StateObject private var session = AppSession()  // ≈ Zustand auth store (owned here)

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)   // ≈ React Context Provider
                .preferredColorScheme(.light)
        }
    }
}
```

File: `Nectar/App/NectarApp.swift`

### Root routing (auth gate)

Giống PostPay `MainTabNavigator`: splash → onboarding → login → tabs.

```swift
switch session.route {
case .splash:     SplashView()
case .onboarding: OnboardingView()
case .login:      LoginView()
case .main:       MainTabView()
}
```

File: `Nectar/App/RootView.swift`  
Session logic: `Nectar/App/AppSession.swift`

```
Launch
  → Splash (~1.2s bootstrap)
  → chưa onboarding? → Onboarding
  → có Keychain token? → MainTabView
  → else → Login
```

### Cây thư mục (đọc theo feature)

```
Nectar/
├── App/                 # Entry + session + root switch
├── Core/                # Shared infra (màu, network, keychain, Face ID)
├── Features/            # Mỗi feature ≈ 1 screen folder trong RN
│   ├── Auth/
│   ├── Dashboard/       # Home
│   ├── History/
│   ├── Transfers/
│   ├── Cards/
│   ├── Profile/
│   └── ...
└── Shared/              # Tab bar, row components
```

Trong mỗi feature thường có:

| Folder | Vai trò | Tương đương RN |
|--------|---------|----------------|
| `Presentation/` | View + ViewModel | Screen + hook/store slice |
| `Domain/` | Models + protocol repo | types + interface |
| `Data/` | Mock / API impl | `api.ts` + repository |

---

## 2. Bảng map RN → SwiftUI

### UI & layout

| React Native | SwiftUI | Ghi chú |
|--------------|---------|---------|
| `<View>` | `VStack` / `HStack` / `ZStack` | Flex column / row / absolute-like overlay |
| `style={{ flex: 1 }}` | `.frame(maxWidth: .infinity)` | Không có flexbox giống RN |
| `<Text>` | `Text("...")` | Modifier chain thay vì `style={}` |
| `<TouchableOpacity>` | `Button { } label: { }` | |
| `<ScrollView>` | `ScrollView { }` | |
| `<FlatList>` | `List` / `ForEach` + `LazyVStack` | |
| `<TextInput>` | `TextField` / `SecureField` | Binding `$viewModel.username` |
| `<Image source={...}>` | `Image(systemName:)` / `Image("asset")` | SF Symbols ≈ vector icons |
| `StyleSheet` | View modifiers + `BankColors` | |
| `SafeAreaView` | `.ignoresSafeArea()` / safe area mặc định | |

### State

| React Native | SwiftUI | Khi nào dùng |
|--------------|---------|--------------|
| `useState` | `@State` | State local của **một** View |
| `useRef` giữ instance | `@StateObject` | View **tạo & sở hữu** ViewModel |
| props object / store slice | `@ObservedObject` | ViewModel truyền từ ngoài vào |
| Context / Zustand global | `@EnvironmentObject` | Session toàn app |
| Zustand `set({ x })` | `@Published var x` trong `ObservableObject` | Đổi → UI re-render |
| `useEffect(() => {}, [])` | `.task { }` / `.onAppear` | Load data khi vào màn |
| Pull-to-refresh | `.refreshable { }` | |

### Navigation

| React Navigation | SwiftUI |
|------------------|---------|
| Stack Navigator | `NavigationStack` |
| Tab Navigator | `TabView` + `.tabItem` |
| `navigation.navigate('X')` | `NavigationLink { X() }` |
| typed params | `navigationDestination(for:)` |
| auth gate root | `RootView` + `AppSession.route` |
| MMKV auth token | `KeychainService` + `AppStorageService` |

### Data / async

| RN / PostPay | SwiftUI repo |
|--------------|--------------|
| `async/await` + fetch | `async/await` + (sau này) `URLSession` |
| Zustand store | `ObservableObject` ViewModel |
| service layer `api.ts` | `*Repository` + `MockBankStore` |
| Axios interceptors | (chưa) — sẽ gắn trong `APIClient` |
| `try/catch` | `do/catch` + `throws` |

---

## 3. Swift basics bạn cần trước UI

Không cần học hết Swift — đủ để đọc repo:

### `struct` vs `class`

| | `struct` | `class` |
|--|----------|---------|
| Copy | Value type (copy khi gán) | Reference type |
| Dùng cho | Models (`BankAccount`), Views | ViewModel, Store, Service |
| RN gần với | plain object / immer draft | class instance / Zustand store object |

```swift
struct BankAccount { ... }           // model — Domains/BankModels.swift
final class DashboardViewModel ...   // state holder — class
```

### `let` / `var`

- `let` = `const`
- `var` = `let` có thể gán lại (không phải `var` hoisting của JS)

### Optional `String?`

≈ TypeScript `string | null | undefined`, nhưng compiler bắt unwrap:

```swift
if let token = session.sessionToken { ... }   // smart cast
token ?? "default"
token?.prefix(12)                             // optional chaining
```

### `enum` có associated value

Rất hay dùng cho UI state (giống discriminated union TS):

```swift
enum Status: Equatable {
    case idle
    case loading
    case success
    case failure(String)   // payload kèm theo
}

if case .failure(let message) = viewModel.status {
    StatusBanner(message: message, style: .error)
}
```

### Protocol ≈ interface / TypeScript interface

```swift
protocol AccountRepository {
    func fetchAccounts() async throws -> [BankAccount]
}
```

Mock implement protocol → sau này đổi sang API thật **không sửa View**.

### `async` / `await` / `throws`

Gần JS:

```swift
func load() async {
    do {
        accounts = try await accountRepo.fetchAccounts()
    } catch {
        status = .failure(error.localizedDescription)
    }
}
```

`@MainActor` trên ViewModel = “mọi update property chạy trên main thread” (tránh crash UI). Trong RN bạn ít phải nghĩ chuyện này vì JS single-thread; trên iOS bắt buộc.

---

## 4. View = Component (nhưng là `struct`)

### Anatomy

```swift
struct DashboardView: View {
    // 1) Dependencies / state
    @EnvironmentObject private var session: AppSession
    @StateObject private var viewModel = DashboardViewModel()
    @State private var balanceHidden = false

    // 2) body = JSX return
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    walletCard
                }
            }
            .task { await viewModel.load() }      // useEffect mount
            .refreshable { await viewModel.load() }
        }
    }

    // 3) Subviews = function components
    private var header: some View {
        HStack { ... }
    }
}
```

`some View` = “trả về **một** kiểu View cụ thể, compiler tự suy” (opaque return type). Không cần viết giống `React.FC`.

### Modifier chain ≈ style props

```swift
Text("Nectar")
    .font(BankTypography.largeTitle)
    .foregroundStyle(.white)
    .padding()
```

Đọc **từ trên xuống**: mỗi dòng bọc view trước đó (giống compose HOC, nhưng cho layout/style).

### Tách subview

Trong RN: `<Header />`.  
Trong SwiftUI: `private var header: some View` hoặc `struct Header: View`.

---

## 5. State — useState / Zustand / Context

### `@State` — local UI state

```swift
@State private var balanceHidden = false
```

≈ `const [balanceHidden, setBalanceHidden] = useState(false)`

Chỉ dùng cho state **nhẹ, thuộc View** (toggle mắt ẩn số dư, selected tab local…).

### `@StateObject` — sở hữu ViewModel

```swift
@StateObject private var viewModel = DashboardViewModel()
```

≈ tạo Zustand store **một lần** khi mount screen, không recreate mỗi re-render.

**Quy tắc vàng:** View nào `= DashboardViewModel()` thì dùng `@StateObject`. Nếu nhận từ cha → `@ObservedObject`.

### `@Published` — field trong ViewModel

```swift
@Published private(set) var accounts: [BankAccount] = []
@Published var amountText = ""   // form field — 2-way bind
```

`private(set)` = bên ngoài chỉ đọc, ViewModel mới được gán (giống selector readonly).

Trong View, binding form:

```swift
TextField("VD: 500000", text: $viewModel.amountText)
```

Dấu `$` = **Binding** (đọc + ghi). Giống controlled input `value` + `onChangeText`.

### `@EnvironmentObject` — Context

```swift
// Provider (App)
.environmentObject(session)

// Consumer (bất kỳ View con)
@EnvironmentObject private var session: AppSession
```

≈ `AuthContext`. Dùng cho session / theme / DI container nhẹ.

### So sánh nhanh với Zustand (PostPay)

| Zustand | Repo này |
|---------|----------|
| `useAuthStore()` | `@EnvironmentObject var session: AppSession` |
| `useHomeStore()` / screen store | `@StateObject var viewModel = DashboardViewModel()` |
| `set({ balance })` | `self.accounts = ...` trên `@Published` |
| persist MMKV | `AppStorageService` + `KeychainService` |

---

## 6. Navigation — React Navigation → SwiftUI

### Auth stack (root)

Không dùng library router. `AppSession.route` quyết định màn root — giống điều kiện `accessToken ? AppStack : AuthStack` trong PostPay.

### Tabs

File: `Shared/Shell/MainTabView.swift`

```swift
TabView {
    DashboardView()
        .tabItem { Label("Trang chủ", systemImage: "house.fill") }
    NavigationStack { HistoryView() }
        .tabItem { Label("Lịch sử", systemImage: "clock.arrow.circlepath") }
    // ...
}
.tint(BankColors.brand)
```

≈ React Navigation Bottom Tabs. Mỗi tab có thể bọc `NavigationStack` riêng (stack per tab — giống RN hay làm).

### Push màn trong stack

```swift
NavigationLink {
    TransferView()
} label: {
    QuickActionChip(title: "Chuyển tiền", icon: "arrow.left.arrow.right")
}
```

Hoặc typed destination:

```swift
.navigationDestination(for: String.self) { accountId in
    AccountDetailView(accountId: accountId)
}

NavigationLink(value: account.id) {
    AccountRow(account: account)
}
```

≈ `navigation.navigate('AccountDetail', { id })`.

### Dismiss (goBack)

```swift
@Environment(\.dismiss) private var dismiss
dismiss()
```

≈ `navigation.goBack()`.

---

## 7. Architecture & data flow

### Luồng chuẩn (học thuộc)

```
View (SwiftUI)
  → gọi viewModel.load() / submit()
      → Repository protocol  (Domain)
          → Mock*Repository  (Data)
              → MockBankStore / MockBankAPI
```

Sau này thay `Mock*Repository` bằng `API*Repository` dùng `URLSession` — **View không đổi**.

### Vì sao có protocol?

Giống PostPay tách `api.ts` khỏi screen. Protocol = contract:

```swift
protocol TransferRepository {
    func fetchBeneficiaries() async throws -> [Beneficiary]
    func submit(_ request: TransferRequest) async throws -> TransferResult
}
```

`MockTransferRepository` implement → trừ tiền + ghi lịch sử trong `MockBankStore`.

### DI kiểu đơn giản (constructor default)

```swift
init(
    accountRepo: AccountRepository = MockAccountRepository(),
    transferRepo: TransferRepository = MockTransferRepository()
) { ... }
```

≈ default param trong hook/service. Test thì inject fake repo.

### Status pattern (thay BLoC / Redux status)

Gần như mọi ViewModel:

```swift
enum Status: Equatable {
    case idle, loading, success, failure(String)
}
```

UI:

- `loading` → `ProgressView`
- `failure` → `StatusBanner`
- empty list → `EmptyStateView`

Đây là pattern bạn sẽ giải thích trong phỏng vấn iOS banking.

---

## 8. Async / networking

### `.task` = useEffect load

```swift
.task { await viewModel.load() }
```

Chạy khi view xuất hiện; tự cancel nếu view biến mất (tiện hơn nhiều `useEffect` + AbortController thủ công).

### Parallel fetch

```swift
async let accountsTask = accountRepo.fetchAccounts()
async let txsTask = transactionRepo.fetchGlobalRecent(limit: 5)
let loadedAccounts = try await accountsTask
let txs = try await txsTask
```

≈ `Promise.all([getAccounts(), getTxs()])`.

### Mock delay

```swift
await MockBankAPI.delay(450)  // giả latency mạng
```

### `MockBankStore` — vì sao quan trọng?

Trước đây mock **stateless** → chuyển tiền xong số dư không đổi (demo “giả”).  
Giờ store **mutable in-memory**:

1. Trừ `availableBalance`
2. Insert transaction đầu list
3. (Optional) thêm beneficiary mới

→ Home + History refresh sẽ thấy thay đổi — vòng feedback giống app thật.

File: `Core/Network/MockBankStore.swift`

### `APIClient` hiện tại

Stub — chỗ dành sẵn để gắn PostPay base URL / Bearer token sau. Đừng confuse: **runtime đang đi qua Mock**.

---

## 9. Đọc từng feature quan trọng

Học bằng cách mở file theo thứ tự dưới đây (1–2 giờ/feature).

### 9.1 Session & Auth

| File | Việc cần hiểu |
|------|----------------|
| `App/AppSession.swift` | `route`, `loginSucceeded`, `logout`, bootstrap |
| `Core/Storage/AppStorageService.swift` | Onboarding flag (UserDefaults) + session (Keychain) |
| `Core/Storage/KeychainService.swift` | SecItem add/get/delete |
| `Features/Auth/Presentation/LoginView.swift` | UI form + binding |
| `Features/Auth/Presentation/LoginViewModel.swift` | Validate demo/123456 + Face ID |

**Flow login password:**

1. User bấm Đăng nhập  
2. `LoginViewModel.loginWithPassword()` delay + check credential  
3. `session.loginSucceeded(displayName:)` → `createSession()` vào Keychain → `route = .main`

**Flow biometric:** `BiometricAuthService.authenticate` → cùng `loginSucceeded`.

### 9.2 Home (Dashboard)

| File | Việc cần hiểu |
|------|----------------|
| `DashboardView.swift` | Layout: header, wallet card, quick actions, accounts, recent |
| `DashboardViewModel.swift` | Parallel load accounts + global txs; `totalBalanceVND` |

Điểm PostPay-like:

- Ẩn/hiện số dư (`balanceHidden`)
- Actions trên thẻ ví: Chuyển / Nạp / Rút / QR (Nạp–Rút–QR đang placeholder)
- Error banner khi `status == .failure`

### 9.3 Transfer (quan trọng nhất để hiểu MVVM)

| File | Việc cần hiểu |
|------|----------------|
| `TransferView.swift` | 3 step UI: form / confirm / success |
| `TransferViewModel.swift` | Validation, recipient mode, Face ID confirm, submit |

**State machine:**

```
form → validateAndConfirm() → confirm → submit() → success
         ↑                      │
         └──── goBackToForm() ──┘
```

**Recipient:**

- `.saved` → chọn từ list
- `.new` → name + bank + account number (mask `**** 1234`)

**Submit:**

1. (Nếu bật biometric) Face ID  
2. `transferRepo.submit(request)`  
3. Store trừ tiền + prepend tx  
4. Reload accounts/beneficiaries trên VM  
5. Hiện reference id `FT…`

Đây là flow phỏng vấn hay hỏi: *“Bạn validate và confirm transfer thế nào?”*

### 9.4 History

| File | Việc cần hiểu |
|------|----------------|
| `HistoryView.swift` | Filter chips + List |
| `HistoryViewModel.swift` | `fetchGlobalRecent`, filter all / inOut / transfer |

Tab riêng + link “Xem tất cả” từ Home.

### 9.5 Cards & Profile

- **Cards:** freeze/unfreeze qua `MockCardRepository` → mutate `MockBankStore.cards`
- **Profile:** toggle biometric, placeholder màn (ví / bank link / PIN), logout clear Keychain

### 9.6 Domain models

File: `Features/Accounts/Domain/BankModels.swift`

Đọc kỹ:

- `BankAccount` — `Decimal` balance (không dùng `Double` cho tiền)
- `Transaction` — `amount` âm = chi
- `TransferRequest` — hỗ trợ saved **hoặc** new recipient
- `TransferResult` — `referenceId`

---

## 10. Design system

| File | Nội dung |
|------|----------|
| `Core/DesignSystem/BankColors.swift` | Brand `#0A4BB3` (gần PostPay) |
| `Core/DesignSystem/BankTypography.swift` | Font scale |
| `Shared/Components/BankRows.swift` | `AccountRow`, `TransactionRow`, `EmptyStateView`, `StatusBanner` |
| `Core/Utils/MoneyFormatter.swift` | Format VND |

**Thói quen:** không hardcode màu trong feature — dùng `BankColors.brand`.

RN tương đương: `theme/palettes.ts` + `BaseText`.

---

## 11. Bảo mật: Keychain + Face ID

### Keychain vs UserDefaults vs MMKV

| Lưu gì | RN thường dùng | iOS đúng chuẩn |
|--------|----------------|----------------|
| Onboarding flag | MMKV / AsyncStorage | UserDefaults ✅ |
| Access token | MMKV (nhiều app) | **Keychain** ✅ |
| Biometric enabled | MMKV | UserDefaults OK |

Repo: token qua `KeychainService`; flag biometric / ẩn số dư qua UserDefaults.

### Face ID

File: `Core/Security/BiometricAuthService.swift`

- Dùng `LocalAuthentication`
- Cần `NSFaceIDUsageDescription` trong `Info.plist`
- Simulator: **Features → Face ID → Enrolled**, rồi Matching/Non-matching khi test

Dùng ở:

1. Login  
2. Xác nhận chuyển tiền (`TransferViewModel.submit`)

---

## 12. Debug & Xcode tips

### Chạy app

```bash
open Nectar.xcodeproj
```

`⌘R` Run · `⌘.` Stop · `⌘B` Build

### Đặt breakpoint

Click số dòng (xanh) — giống debugger Chrome, nhưng native. Khi hit: xem biến ở panel trái.

### Preview (tuỳ file)

Một số View có thể thêm:

```swift
#Preview {
    DashboardView()
        .environmentObject(AppSession())
}
```

Canvas bên phải Xcode — iterate UI nhanh hơn rebuild full (không phải lúc nào cũng thay simulator).

### Log

```swift
print("accounts:", accounts.count)
```

Xem trong console Xcode (dưới).

### Credential demo

- User: `demo`
- Pass: `123456`

---

## 13. Checklist học (thực hành)

Làm theo thứ tự; tick khi giải thích được **bằng lời** + chỉ đúng file.

### Ngày 1–2 — UI & state

- [ ] Đổi `BankColors.brand`, chạy lại, thấy Home/Login đổi màu
- [ ] Giải thích khác nhau `@State` / `@StateObject` / `@EnvironmentObject` trên `DashboardView`
- [ ] Thêm text “Secure by design” dưới logo Splash

### Ngày 3–4 — Navigation & tabs

- [ ] Thêm tab **Ưu đãi** (placeholder `Text`)
- [ ] Từ Home `NavigationLink` sang một màn mới tự tạo

### Ngày 5–7 — ViewModel & transfer

- [ ] Đọc hết `TransferViewModel`, vẽ state machine ra giấy
- [ ] Đổi hạn mức `100_000_000` trong store, thử vượt hạn mức
- [ ] Giải thích vì sao sau transfer, History có dòng mới

### Ngày 8–10 — Architecture

- [ ] Viết 5 dòng: protocol vs mock vs store
- [ ] (Nâng cao) Gọi `URLSession` JSONPlaceholder trong một repo method, vẫn giữ protocol

### Ngày 11–14 — Security & portfolio

- [ ] Demo Face ID trên simulator khi chuyển tiền
- [ ] Giải thích Keychain vs UserDefaults trong 60 giây
- [ ] Đọc `docs/banking-interview.md` và trả lời to thành tiếng

Chi tiết lộ trình dài hơn: [learning-path.md](./learning-path.md)

---

## 14. Lỗi tư duy hay gặp khi từ RN sang

1. **Tìm `setState` mọi nơi** — phần lớn state nằm ViewModel `@Published`, không nằm View.
2. **Tạo ViewModel bằng `@ObservedObject var vm = VM()`** — sai: mỗi re-render có thể tạo mới → dùng `@StateObject`.
3. **Quên `$` binding** — `TextField(..., text: viewModel.x)` không compile; cần `$viewModel.x`.
4. **Think flexbox** — dùng `VStack`/`HStack`/`Spacer`/`frame`, không có `flex: 1` giống Yoga.
5. **Mutate model `let` properties** — `struct` fields thường `let`; cập nhật = tạo bản mới (xem `MockBankStore.applyTransfer`).
6. **Gọi API trên background rồi sửa UI** — luôn `@MainActor` ViewModel hoặc `await MainActor.run`.
7. **So SwiftUI với HTML** — gần “declarative component tree” hơn HTML; modifiers ≈ style system.

---

## File map nhanh (in ra / bookmark)

```
App/
  NectarApp.swift   ← @main, inject session
  RootView.swift              ← auth gate
  AppSession.swift            ← route + login/logout

Core/
  DesignSystem/BankColors.swift
  DesignSystem/BankTypography.swift
  Network/MockBankStore.swift ← source of truth mock
  Network/MockBankAPI.swift
  Network/APIClient.swift     ← stub future real API
  Storage/AppStorageService.swift
  Storage/KeychainService.swift
  Security/BiometricAuthService.swift
  Utils/MoneyFormatter.swift
  Errors/AppError.swift

Features/
  Auth/Presentation/LoginView(+Model).swift
  Dashboard/Presentation/DashboardView(+Model).swift
  History/Presentation/HistoryView(+Model).swift
  Transfers/Presentation/TransferView(+Model).swift
  Cards/Presentation/CardsView(+Model).swift
  Profile/Presentation/ProfileView.swift
  Accounts/...                ← detail + domain + mock repos

Shared/
  Shell/MainTabView.swift
  Components/BankRows.swift
```

---

## Tài liệu liên quan trong repo

| Doc | Nội dung |
|-----|----------|
| [architecture.md](./architecture.md) | Layer Domain/Data/Presentation |
| [learning-path.md](./learning-path.md) | Lộ trình 4 tuần (RN → iOS) |
| [banking-interview.md](./banking-interview.md) | Câu hỏi phỏng vấn gắn project |

Khi đọc xong doc này, mở Xcode và chạy **một vòng**: Login → Home → Chuyển 50.000 → History. Vừa click vừa đối chiếu section 9 — đó là cách học nhanh nhất từ RN sang SwiftUI.
