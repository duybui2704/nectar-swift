# Level 1 — Nền tảng SwiftUI (bài giảng cho intern)

Học đến khi tự đọc được toàn bộ `Nectar` và giải thích được **từng dòng**. Mỗi phần: khái niệm → code trong repo → pitfall.

> Ghi chú: các đường dẫn code trỏ vào file thật của repo. Mở song song để đối chiếu.

## Mục lục

1. [Ngôn ngữ Swift cơ bản](#1-ngôn-ngữ-swift-cơ-bản)
2. [Async/await](#2-async--await)
3. [View & Component](#3-view--component)
4. [Property Wrappers — quản lý state](#4-property-wrappers--quản-lý-state)
5. [Lifecycle & Side Effect](#5-lifecycle--side-effect)
6. [Navigation](#6-navigation)
7. [Kiến trúc cơ bản — MVVM](#7-kiến-trúc-cơ-bản--mvvm)
8. [State management đơn giản](#8-state-management-đơn-giản)
9. [Performance cơ bản](#9-performance-cơ-bản)

---

## 1. Ngôn ngữ Swift cơ bản

### 1.1 `let` vs `var`

| Từ khóa | Ý nghĩa | Tương đương JS |
|---------|---------|-----------------|
| `let`   | Hằng — không gán lại được | `const` |
| `var`   | Biến — gán lại được | `let` (JS) |

```swift
let brand = "Nectar"   // OK
// brand = "Other"        // compile error

var count = 0
count += 1                 // OK
```

**Nguyên tắc senior:** mặc định luôn `let`; chỉ đổi thành `var` khi buộc phải mutate. Compiler ép bạn suy nghĩ kỹ trước khi mutate — đây là an toàn miễn phí.

Xem [`BankModels.swift`](../Nectar/Features/Accounts/Domain/BankModels.swift) — tất cả field trong `BankAccount` đều `let` để đảm bảo model bất biến.

### 1.2 Optional (`?`, `!`, `??`, `if let`, `guard let`)

Optional = "value hoặc `nil`". Bắt buộc unwrap trước khi dùng — compiler bắt bạn xử lý `nil`.

```swift
var token: String? = nil          // có thể nil
token = "abc"

// Cách unwrap an toàn:
if let value = token {
    print("token =", value)       // chạy khi != nil
}

// guard let: early return
func send(token: String?) {
    guard let token else { return }   // nil -> thoát ngay
    print(token.count)                // đến đây token là non-optional
}

// Nil-coalescing
let display = token ?? "no-token"

// Optional chaining
let length = token?.count            // Int? (nil nếu token nil)

// Force unwrap (!): TUYỆT ĐỐI TRÁNH trong production
let unsafe = token!                  // crash nếu nil
```

Ví dụ trong repo: [`AppStorageService.swift`](../Nectar/Core/Storage/AppStorageService.swift):
```swift
var sessionToken: String? {
    KeychainService.get(forKey: Keys.sessionToken)
}
```

**Pitfall:** `!` (force unwrap) là "cho tôi crash nếu sai". Trong banking KHÔNG BAO GIỜ dùng `!` với dữ liệu runtime. Chỉ chấp nhận với hằng compile-time (vd `URL(string: "https://...")!`).

**Interview:** "Vì sao Swift bắt unwrap?" → an toàn: crash `nil` runtime của Java/JS được đẩy thành compile error.

### 1.3 `struct` vs `class` — value type vs reference type

| | `struct` | `class` |
|---|---------|---------|
| Gán | **Copy** (value type) | **Chia sẻ** (reference) |
| Concurrency | An toàn hơn | Cần đồng bộ hóa |
| Kế thừa | Không | Có |
| Dùng cho | Model, View | ViewModel, Service |

```swift
struct BankAccount {
    let id: String
    var balance: Decimal
}

var a = BankAccount(id: "1", balance: 100)
var b = a               // COPY
b.balance = 999
print(a.balance)        // 100 — a không bị ảnh hưởng
```

```swift
final class DashboardViewModel: ObservableObject { /* ... */ }

let vm1 = DashboardViewModel()
let vm2 = vm1            // cùng instance
// vm1 và vm2 trỏ cùng object
```

Trong repo:
- Model là `struct`: `BankAccount`, `Transaction`, `BankCard` ([`BankModels.swift`](../Nectar/Features/Accounts/Domain/BankModels.swift))
- ViewModel là `final class`: [`DashboardViewModel`](../Nectar/Features/Dashboard/Presentation/DashboardViewModel.swift)
- View cũng là `struct` (SwiftUI View phải là struct — nhẹ, dựng lại rẻ)

**Nguyên tắc chọn:**
- Dữ liệu bất biến, không cần identity → `struct`
- Có state chia sẻ nhiều nơi, cần identity → `class`
- SwiftUI View → **luôn** `struct`

### 1.4 Protocol & Extension

**Protocol** ≈ interface (TypeScript). Định nghĩa "khả năng" mà không quan tâm implement.

```swift
protocol AccountRepository {
    func fetchAccounts() async throws -> [BankAccount]
    func fetchAccount(id: String) async throws -> BankAccount
}

final class MockAccountRepository: AccountRepository {
    func fetchAccounts() async throws -> [BankAccount] { /* ... */ }
    func fetchAccount(id: String) async throws -> BankAccount { /* ... */ }
}
```

Xem [`BankRepositories.swift`](../Nectar/Features/Accounts/Domain/BankRepositories.swift) và các mock/API impl trong [`Features/Accounts/Data`](../Nectar/Features/Accounts/Data/).

**Extension** = thêm phương thức vào type có sẵn (kể cả `String`, `Int`).

```swift
extension String {
    var digitsOnly: String { filter(\.isNumber) }
}

"090-1234 5678".digitsOnly       // "09012345678"
```

Trong repo: [`BankColors.swift`](../Nectar/Core/DesignSystem/BankColors.swift) extend `Color` với init từ hex:
```swift
extension Color {
    init(hex: UInt, alpha: Double = 1) { /* ... */ }
}
Color(hex: 0x0A4BB3)
```

**Interview:** "Vì sao dùng protocol thay vì class kế thừa?"
→ Composition over inheritance. Test dễ (inject mock). Swift khuyến khích protocol-oriented programming.

### 1.5 Closure

Closure = function anonymous. Giống arrow function JS.

```swift
// Signature: (Int, Int) -> Int
let add: (Int, Int) -> Int = { a, b in a + b }
add(2, 3)  // 5

// Trailing closure — cực phổ biến SwiftUI:
Button("Login") {
    print("tapped")           // đây là closure
}

// Với async
Task {
    let data = try await api.fetch()
}
```

**Escaping closure:** closure sống lâu hơn hàm gọi (vd trong async).
```swift
func loadLater(completion: @escaping (String) -> Void) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
        completion("done")
    }
}
```

Trong SwiftUI, `body` là **`@ViewBuilder` closure** (xem mục 3.3).

---

## 2. Async / await

### 2.1 async/await cơ bản

Trước đây iOS dùng callback / Combine. Từ iOS 15+ có `async/await` — code tuần tự, dễ đọc như đồng bộ.

```swift
func loginWithPassword() async -> Bool {
    status = .loading
    await MockBankAPI.delay(500)          // "sleep" không block thread
    guard username == "demo", password == "123456" else {
        status = .error("Sai thông tin.")
        return false
    }
    status = .idle
    return true
}
```

Xem [`LoginViewModel.swift`](../Nectar/Features/Auth/Presentation/LoginViewModel.swift).

Gọi async từ SwiftUI dùng `Task`:
```swift
Button("Login") {
    Task {
        if await viewModel.loginWithPassword() {
            session.loginSucceeded(displayName: MockBankAPI.customerName)
        }
    }
}
```

### 2.2 `Task`, `Task.sleep`

`Task` = "chạy một job async". Có priority, có thể cancel.

```swift
Task {
    try? await Task.sleep(nanoseconds: 1_200_000_000)   // 1.2s
    await session.bootstrap()
}
```

**Cancel tự động:** khi View biến mất, `.task {}` tự cancel Task bên trong — không cần `AbortController` như JS.

### 2.3 `throws` / `do/catch`

Hàm có thể `throw` lỗi:

```swift
func applyTransfer(_ request: TransferRequest, beneficiary: Beneficiary) throws -> TransferResult {
    guard request.amount >= TransferConstants.minimumAmountVND else {
        throw AppError.validation("Số tiền tối thiểu ...")
    }
    // ...
    return TransferResult(referenceId: "FT...", completedAt: Date())
}
```

Gọi phải `try` và bắt bằng `do/catch`:

```swift
do {
    let result = try await transferRepo.submit(request)
    step = .success(result)
} catch {
    status = .error(error.localizedDescription)
}
```

Xem [`TransferViewModel.submit`](../Nectar/Features/Transfers/Presentation/TransferViewModel.swift) — pattern gọn.

**Biến thể `try`:**
- `try` — bắt buộc `do/catch`
- `try?` — nếu lỗi thì trả `nil`
- `try!` — crash nếu lỗi (tránh dùng)

### 2.4 `async let` — parallel


Chạy nhiều task song song, chờ kết quả cuối:

```swift
async let accountsTask = accountRepo.fetchAccounts()
async let txsTask = transactionRepo.fetchGlobalRecent(limit: 5)
let loadedAccounts = try await accountsTask
let txs = try await txsTask
```

Tương đương `Promise.all` bên JS. Xem [`DashboardViewModel.load`](../Nectar/Features/Dashboard/Presentation/DashboardViewModel.swift).

**Interview:** "Vì sao dùng `async let`?" → Song song, tiết kiệm thời gian tổng khi các call độc lập (accounts và transactions không phụ thuộc nhau).

---

## 3. View & Component

### 3.1 `View` protocol + `body`

Mọi màn hình/component đều `struct` implement `View`:

```swift
struct WalletCardView: View {
    let totalBalanceVND: Decimal
    @Binding var balanceHidden: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Số dư khả dụng")
            Text(MoneyFormatter.format(totalBalanceVND))
        }
    }
}
```

`some View` = opaque return type: "một loại View, compiler tự suy ra". Đừng viết `AnyView` thay thế (mục 9.2).

### 3.2 Custom View — tách tái sử dụng

Nguyên tắc: nếu code UI dùng ở ≥2 nơi, hoặc `body` quá 40 dòng → tách sub-view.

Ví dụ tách trong repo:
- [`WalletCardView`](../Nectar/Features/Dashboard/Components/WalletCardView.swift) tách khỏi `DashboardView`
- [`AccountRow`, `TransactionRow`, `StatusBanner`, `EmptyStateView`](../Nectar/Shared/Components/BankRows.swift) dùng khắp app

Lợi ích:
1. **Perf:** state đổi trong sub-view không rebuild toàn Dashboard
2. **Test:** viết Preview cho sub-view độc lập
3. **Readability:** body cha ngắn, hiểu ngay

### 3.3 `@ViewBuilder`

Cho phép closure trả **nhiều View** hoặc `if/switch` bên trong body:

```swift
struct StatusView: View {
    let status: DashboardViewModel.Status

    var body: some View {
        // Tự động là @ViewBuilder
        if status == .loading {
            ProgressView()
        } else if case .failure(let msg) = status {
            Text(msg).foregroundStyle(.red)
        } else {
            EmptyView()
        }
    }
}
```

Khi tự viết helper trả View, thêm `@ViewBuilder`:

```swift
@ViewBuilder
private func content() -> some View {
    if isLoading {
        ProgressView()
    } else {
        Text("Loaded")
    }
}
```

Xem [`HistoryView.content`](../Nectar/Features/History/Presentation/HistoryView.swift) — dùng `@ViewBuilder` để switch state.

### 3.4 ViewModifier (built-in + custom)

Modifier = hàm bọc View, thay đổi/thêm hành vi. Cực nhiều built-in: `.padding()`, `.background()`, `.clipShape()`...

```swift
Text("Hello")
    .padding()
    .background(BankColors.brandSoft)
    .clipShape(RoundedRectangle(cornerRadius: 12))
```

Đọc từ trên xuống — mỗi dòng bọc View trước đó.

**Custom ViewModifier** để đóng gói style lặp lại:

```swift
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(BankColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(BankColors.border, lineWidth: 1))
    }
}

extension View {
    func cardStyle() -> some View { modifier(CardStyle()) }
}

// Dùng:
Text("Row").cardStyle()
```

Style card trong [`AccountRow`, `QuickActionChip`] đều có thể refactor thành `.cardStyle()`.

**Interview:** "ViewModifier khác gì HOC React?" → Cùng ý tưởng compose behavior, nhưng ViewModifier là struct type-safe, không có nested props hell.

---

## 4. Property Wrappers — quản lý state

Đây là **cốt lõi** SwiftUI. Sai property wrapper → bug reactive.

### 4.1 `@State` — state cục bộ của View

```swift
struct DashboardView: View {
    @State private var balanceHidden = AppStorageService.shared.balanceHidden
    // ...
}
```

Đặc điểm:
- **Chỉ dùng trong View**, thuộc View đó
- SwiftUI tự lưu ngoài struct (View bị recreate mỗi frame, nhưng `@State` giữ giá trị)
- Đổi giá trị → SwiftUI diff và re-render

**Quy tắc:** dùng cho state **UI nhỏ** (toggle, form field, tab selection). Nếu state cần dùng ở ViewModel / nhiều View → không phải chỗ của `@State`.

### 4.2 `@Binding` — hai chiều "borrow" state từ cha

```swift
struct WalletCardView: View {
    @Binding var balanceHidden: Bool    // nhận từ ngoài
    var body: some View {
        Button {
            balanceHidden.toggle()       // đổi ở đây, cha thấy
        } label: { Image(systemName: balanceHidden ? "eye.slash" : "eye") }
    }
}

// Cha:
WalletCardView(balanceHidden: $balanceHidden)   // dấu $ = binding
```

Xem [`WalletCardView`](../Nectar/Features/Dashboard/Components/WalletCardView.swift) + [`DashboardView`](../Nectar/Features/Dashboard/Presentation/DashboardView.swift).

**Pitfall:** đừng dùng `@Binding` cho toàn ViewModel — chỉ cho state đơn giản (Bool, String).

### 4.3 `@ObservedObject` / `@StateObject` — dùng với ViewModel

Cả hai đều bind với `ObservableObject`. Khác nhau ai **sở hữu** ViewModel:

| | Ai tạo VM | Khi View recreate |
|---|-----------|-------------------|
| `@StateObject` | View **này** tạo | VM giữ nguyên |
| `@ObservedObject` | Nhận từ ngoài | Nếu cha đưa VM mới → View dùng VM mới |

```swift
// Đúng:
struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    // ...
}

// Sai (VM sẽ bị tạo lại mỗi lần cha rebuild):
struct DashboardView: View {
    @ObservedObject var viewModel = DashboardViewModel()   // ⚠️
}
```

**Quy tắc vàng:** ai `= ViewModel()` thì dùng `@StateObject`. Nhận từ ngoài (props) thì `@ObservedObject`.

Xem toàn bộ ViewModel trong [`Features/*/Presentation`](../Nectar/Features/).

### 4.4 `@EnvironmentObject` — inject từ root (≈ Context/DI)

Provider ở root:
```swift
@main
struct NectarApp: App {
    @StateObject private var session = AppSession()
    var body: some Scene {
        WindowGroup {
            RootView().environmentObject(session)
        }
    }
}
```

Consumer bất kỳ đâu trong cây:
```swift
struct DashboardView: View {
    @EnvironmentObject private var session: AppSession
    // dùng session.userDisplayName
}
```

Xem [`NectarApp.swift`](../Nectar/App/NectarApp.swift), [`RootView.swift`](../Nectar/App/RootView.swift), [`AppSession.swift`](../Nectar/App/AppSession.swift).

**Pitfall:** quên `.environmentObject(...)` → **crash runtime** khi View đọc `@EnvironmentObject`. Xcode Preview cũng crash nếu thiếu.

### 4.5 `@Environment` — giá trị hệ thống

Đọc giá trị từ system environment (colorScheme, dismiss, locale...):

```swift
struct TransferView: View {
    @Environment(\.dismiss) private var dismiss     // đóng sheet/NavigationLink
    @Environment(\.colorScheme) private var scheme  // .light / .dark

    var body: some View {
        Button("Close") { dismiss() }
    }
}
```

Có thể custom giá trị qua `EnvironmentKey` — xem [Level 2 mục DI](./level-2-advanced.md#3-dependency-injection--context).

### 4.6 `@FocusState` — điều khiển bàn phím focus

Chuyển focus giữa các `TextField` bằng code:

```swift
enum Field { case name, account }

struct RecipientForm: View {
    @FocusState private var focus: Field?
    @State private var name = ""
    @State private var account = ""

    var body: some View {
        VStack {
            TextField("Tên", text: $name).focused($focus, equals: .name)
            TextField("STK", text: $account).focused($focus, equals: .account)

            Button("Sang STK") { focus = .account }
        }
    }
}
```

Banking dùng nhiều: OTP 6 ô, PIN 6 số. Kết hợp với `.onSubmit { }` để enter → next field.

---

## 5. Lifecycle & Side Effect

### 5.1 `.onAppear` / `.onDisappear`

Chạy sync (không async) khi view xuất hiện / biến mất:

```swift
DashboardView()
    .onAppear { print("shown") }
    .onDisappear { print("hidden") }
```

**Pitfall:** `.onAppear` có thể chạy **nhiều lần** khi navigation push-pop. Đừng dùng để load API trực tiếp (dễ trùng call).

### 5.2 `.task {}` — modifier chuẩn cho async work

```swift
DashboardView()
    .task { await viewModel.load() }
```

Đặc điểm:
- Chạy async khi view xuất hiện
- **Tự cancel** khi view biến mất — an toàn hơn `.onAppear + Task { }`
- Tương đương `useEffect(() => { fetch() }, [])` (mount only)

Xem [`DashboardView.body`](../Nectar/Features/Dashboard/Presentation/DashboardView.swift), [`HistoryView.body`](../Nectar/Features/History/Presentation/HistoryView.swift).

### 5.3 `.onChange(of:)` — react khi giá trị đổi

```swift
Toggle("Face ID", isOn: $biometricEnabled)
    .onChange(of: biometricEnabled) { _, newValue in
        AppStorageService.shared.biometricEnabled = newValue
    }
```

Signature iOS 17+: `(_ oldValue, _ newValue)`.

Trong repo: [`ProfileView`](../Nectar/Features/Profile/Presentation/ProfileView.swift), [`OTPInputView`](../Nectar/Shared/Components/OTPInputView.swift):
```swift
.onChange(of: code) { _, newValue in
    let digits = newValue.filter(\.isNumber)
    code = String(digits.prefix(length))
}
```

**Pitfall:** `.onChange` không chạy khi state khởi tạo — chỉ khi **đổi** giá trị. Load ban đầu dùng `.task`.

---

## 6. Navigation

### 6.1 `NavigationStack` + `NavigationLink`

Stack navigator: push/pop màn.

```swift
NavigationStack {
    List(accounts) { account in
        NavigationLink {
            AccountDetailView(accountId: account.id)  // push
        } label: {
            AccountRow(account: account)
        }
    }
    .navigationTitle("Tài khoản")
}
```

### 6.2 `.navigationDestination(for:)` — value-based navigation

Push theo **value** (thường là id), View tạo lazy — dễ deep link:

```swift
NavigationStack {
    List(accounts) { account in
        NavigationLink(value: account.id) {
            AccountRow(account: account)
        }
    }
    .navigationDestination(for: String.self) { accountId in
        AccountDetailView(accountId: accountId)
    }
}
```

Xem [`DashboardView`](../Nectar/Features/Dashboard/Presentation/DashboardView.swift):
```swift
.navigationDestination(for: String.self) { accountId in
    AccountDetailView(accountId: accountId)
}
```

### 6.3 `NavigationPath` — điều khiển stack bằng code

```swift
@State private var path = NavigationPath()

NavigationStack(path: $path) {
    RootScreen()
        .navigationDestination(for: String.self) { AccountDetailView(accountId: $0) }
}

// Push từ code:
path.append("acc-checking")
// Pop:
path.removeLast()
// Reset:
path = NavigationPath()
```

Rất tiện cho deep link — parse URL rồi build path.

### 6.4 `TabView`

```swift
TabView {
    DashboardView().tabItem { Label("Trang chủ", systemImage: "house.fill") }
    HistoryView().tabItem { Label("Lịch sử", systemImage: "clock") }
}
.tint(BankColors.brand)
```

Xem [`MainShellView.swift`](../Nectar/Shared/Shell/MainShellView.swift) — 5 tabs + deep link + session lock.

**Pitfall:** mỗi tab thường bọc `NavigationStack` riêng — nếu bạn bọc `NavigationStack` bên ngoài `TabView` sẽ push ra khỏi tab bar.

---

## 7. Kiến trúc cơ bản — MVVM

### 7.1 Ba lớp

```
View (SwiftUI)  ←→  ViewModel (ObservableObject)  ←→  Repository/Service
```

- **View:** không có logic — chỉ đọc state từ VM và render.
- **ViewModel:** giữ state (`@Published`), xử lý logic, gọi Repository.
- **Repository:** trừu tượng nguồn data (mock / API / DB).

Ví dụ [`TransferViewModel`](../Nectar/Features/Transfers/Presentation/TransferViewModel.swift):

```swift
@MainActor
final class TransferViewModel: ObservableObject {
    @Published private(set) var accounts: [BankAccount] = []
    @Published private(set) var step: Step = .form

    private let accountRepo: AccountRepository
    private let transferRepo: TransferRepository

    init(
        accountRepo: AccountRepository = MockAccountRepository(),
        transferRepo: TransferRepository = MockTransferRepository()
    ) {
        self.accountRepo = accountRepo
        self.transferRepo = transferRepo
    }

    func load() async { /* gọi repo, set @Published */ }
}
```

**Quy tắc:**
1. VM `@MainActor` — mọi update UI-facing state đảm bảo main thread.
2. `@Published private(set)` — bên ngoài đọc, chỉ VM ghi (immutable từ View).
3. Repository nhận qua init → dễ inject mock test (DI).

### 7.2 `@MainActor` là gì?

`@MainActor` = "code bên trong luôn chạy main thread". SwiftUI update UI PHẢI main thread — nếu quên → crash / warning.

```swift
@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var accounts: [BankAccount] = []
    // gán accounts từ async safe: đã ở main.
}
```

**Interview:** "Vì sao ViewModel `@MainActor`?" → Publisher `@Published` gửi update về UI; buộc main thread để tránh data race, race condition khi async return từ background.

### 7.3 ViewModifier như HOC

`ViewModifier` không phải architecture, nhưng đây là "HOC" của SwiftUI: đóng gói behavior + style. Xem mục 3.4.

---

## 8. State management đơn giản

### 8.1 `@EnvironmentObject` = global store

`AppSession` giữ user/session toàn app:

```swift
@MainActor
final class AppSession: ObservableObject {
    @Published private(set) var route: Route = .splash
    @Published private(set) var userDisplayName: String

    func loginSucceeded(displayName: String) {
        userDisplayName = displayName
        route = .main
    }
}
```

Provider (root):
```swift
RootView().environmentObject(session)
```

Consumer (bất kỳ):
```swift
@EnvironmentObject private var session: AppSession
```

Xem [`AppSession.swift`](../Nectar/App/AppSession.swift), [`NectarApp.swift`](../Nectar/App/NectarApp.swift).

**Đánh đổi:** đơn giản, không cần TCA/Redux; nhưng dễ "God object" khi nhét mọi thứ vào 1 session — nên tách nhiều `ObservableObject` theo domain.

### 8.2 `@Published` + Combine

Bên trong `ObservableObject`, mọi property `@Published` sẽ tự phát signal khi đổi → View subscribing tự re-render.

```swift
final class OffersViewModel: ObservableObject {
    @Published private(set) var status: Status = .idle
    @Published private(set) var offers: [Offer] = []
}
```

Muốn combine nhiều signal (Combine framework — Level 2 mục 2).

---

## 9. Performance cơ bản

### 9.1 `LazyVStack` / `LazyHStack`

`VStack` render **tất cả** con ngay lập tức — không phù hợp list dài.
`LazyVStack` render **chỉ khi con vào visible** — như `FlatList` bên RN.

```swift
ScrollView {
    LazyVStack(spacing: 0) {
        ForEach(transactions) { tx in
            TransactionRow(transaction: tx)
            Divider()
        }
    }
}
```

Xem [`AccountDetailView`](../Nectar/Features/Accounts/Presentation/AccountDetailView.swift) đã đổi sang `LazyVStack`.

Còn `List` thì tự động lazy — chuẩn cho danh sách banking (History).

### 9.2 Tránh `AnyView`

`AnyView` xóa type → SwiftUI mất khả năng diff nhanh → re-render toàn bộ.

```swift
// Đừng:
var content: AnyView {
    if loading { return AnyView(ProgressView()) }
    return AnyView(Text("Loaded"))
}

// Nên:
@ViewBuilder
var content: some View {
    if loading { ProgressView() } else { Text("Loaded") }
}
```

**Khi nào chấp nhận `AnyView`?** Rất hiếm — chỉ khi trả kiểu View đổi runtime mà không thể dùng `@ViewBuilder` (vd list of heterogeneous views). Trong repo này KHÔNG dùng `AnyView`.

### 9.3 Tách subview để giảm re-render

SwiftUI diff và rebuild chỉ **View có state đổi**. Nếu bạn nhét mọi thứ vào 1 body → mọi thay đổi rebuild cả cây.

**Refactor pattern:** thấy `body` > 40 dòng → tách sub-view như [`WalletCardView`](../Nectar/Features/Dashboard/Components/WalletCardView.swift), [`QuickActionChip`](../Nectar/Features/Dashboard/Presentation/DashboardView.swift).

### 9.4 Instruments — SwiftUI template

Xcode → Product → Profile (`⌘I`) → **SwiftUI**.

Kiểm tra:
- **View body updates** — body nào bị gọi thường xuyên?
- **Long transactions** — spike do body nặng
- **Cause & effect** — state nào trigger update

Chi tiết: xem [`instruments-notes.md`](./instruments-notes.md).

### 9.5 `@Published private(set)`

`private(set)` = bên ngoài chỉ đọc, không ghi. Giảm surface area, tránh view mutate VM ngoài ý định:

```swift
@Published private(set) var accounts: [BankAccount] = []
```

---

## Checklist Level 1 (self-review)

- [ ] Đọc & giải thích được từng dòng [`DashboardView`](../Nectar/Features/Dashboard/Presentation/DashboardView.swift)
- [ ] Vẽ được sơ đồ 3 lớp View → VM → Repo cho flow Transfer
- [ ] Phân biệt `@State`, `@StateObject`, `@ObservedObject`, `@EnvironmentObject`, `@Binding`
- [ ] Giải thích `async let` giảm thời gian load Home thế nào
- [ ] Chạy `⌘R` build & login `demo`/`123456` không lỗi
- [ ] Sửa được 1 modifier (đổi corner radius, color) và thấy đổi ngay

Khi tick hết 6 mục → chuyển [Level 2 — Nâng cao](./level-2-advanced.md).
