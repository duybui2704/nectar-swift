# Level 2 — SwiftUI nâng cao (bài giảng cho intern)

Level 1 dạy bạn "build được app". Level 2 dạy bạn "build được app **banking-grade**": scale, test, an toàn, tương thích native module.

## Mục lục

1. [Kiến trúc nâng cao — TCA vs Observable](#1-kiến-trúc-nâng-cao--tca-vs-observable)
2. [Reactive Programming](#2-reactive-programming)
3. [Dependency Injection & Context](#3-dependency-injection--context)
4. [Animation](#4-animation)
5. [Custom Logic tái sử dụng](#5-custom-logic-tái-sử-dụng)
6. [Networking & Realtime](#6-networking--realtime)
7. [Map](#7-map)
8. [Bảo mật — banking-specific](#8-bảo-mật--banking-specific)

---

## 1. Kiến trúc nâng cao — TCA vs Observable

Ở Level 1 bạn dùng MVVM + `ObservableObject`. Đủ cho app cỡ này, nhưng khi app lớn (100+ màn, 50+ dev) — cần kỷ luật cao hơn. Có 2 trường phái phổ biến:

### 1.1 The Composable Architecture (TCA) — Redux của Swift

TCA (Point-Free) là port của Redux/Elm cho Swift, với 4 khái niệm cốt lõi:

```swift
// State — snapshot toàn bộ dữ liệu feature
struct State: Equatable {
    var accounts: [BankAccount] = []
    var isLoading = false
    var errorMessage: String?
}

// Action — mọi sự kiện xảy ra
enum Action: Equatable {
    case onAppear
    case accountsResponse(Result<[BankAccount], APIError>)
    case refreshTapped
}

// Reducer — thuần chức năng (State, Action) -> State + Effect
@Reducer
struct DashboardFeature {
    @Dependency(\.accountClient) var client
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .run { send in
                    let result = await Result { try await client.fetchAccounts() }
                    await send(.accountsResponse(result))
                }
            case .accountsResponse(.success(let accounts)):
                state.isLoading = false
                state.accounts = accounts
                return .none
            case .accountsResponse(.failure(let error)):
                state.isLoading = false
                state.errorMessage = error.localizedDescription
                return .none
            case .refreshTapped:
                return .send(.onAppear)
            }
        }
    }
}

// Store — kết nối vào View
struct DashboardView: View {
    let store: StoreOf<DashboardFeature>
    var body: some View {
        WithViewStore(store, observe: { $0 }) { viewStore in
            List(viewStore.accounts) { AccountRow(account: $0) }
                .onAppear { viewStore.send(.onAppear) }
        }
    }
}
```

**Ưu điểm TCA:**
- Single source of truth → debug dễ (log action)
- Reducer pure → test bằng đầu vào/đầu ra
- Effect có thể cancel, share bằng ID
- `@Dependency` chuẩn cho DI (mock trong test dễ)

**Nhược điểm:**
- Boilerplate nhiều (State/Action cho mỗi feature)
- Learning curve — dev mới cần 2-4 tuần
- Compile chậm hơn khi feature to (nhiều generic)

### 1.2 Combine / `@Observable` thuần — MobX của Swift

Chính là những gì repo đang dùng. Không có store trung tâm — mỗi feature có `ObservableObject` (hoặc `@Observable` iOS 17+) tự quản state.

```swift
@MainActor
final class DashboardViewModel: ObservableObject {
    @Published private(set) var accounts: [BankAccount] = []
    @Published private(set) var status: Status = .idle

    func load() async { /* … */ }
}
```

**Ưu điểm:**
- Nhẹ, code ít
- SwiftUI hiểu native, không cần lib bên ngoài
- Team nhỏ pick-up trong 1 buổi

**Nhược điểm:**
- Không "single source of truth" — state chia mảnh
- Debug flow phức tạp khó (không có action log)
- Test viewModel với side effect cần mock service (repo đã có `MockRepositories`)

### 1.3 So sánh

| Tiêu chí | TCA | Combine/@Observable |
|----------|-----|---------------------|
| Boilerplate | Nhiều | Ít |
| Test-friendly | Cực tốt | Tốt (nếu inject repo) |
| Debug tracing | Log action miễn phí | Phải tự thêm log |
| Team size | Tốt cho ≥10 dev/feature | Tốt cho team nhỏ/trung |
| Iteration speed | Chậm hơn ban đầu, ổn định lâu dài | Nhanh ban đầu, dễ nhức đầu khi to |

**Khuyến nghị:**
- App banking startup MVP → MVVM + `ObservableObject` (giống repo này)
- Banking core scale (Techcombank/VPBank tier) → TCA cho core flows (transfer, auth, KYC)

Repo dùng `@Observable` iOS 17+ demo trong [`HistoryViewModelObservable`](../Nectar/Features/History/Presentation/HistoryViewModelObservable.swift) — xem mục 3 và Level 1 mục 7.

---

## 2. Reactive Programming

### 2.1 Combine framework — mô hình pub/sub gốc của Apple

3 nhân vật:
- **Publisher:** phát dữ liệu theo thời gian (`Timer.publish`, `NotificationCenter.publisher`, `@Published`)
- **Operator:** biến đổi stream (`map`, `filter`, `debounce`, `combineLatest`)
- **Subscriber:** consume (`sink`, `assign(to:)`, hoặc SwiftUI tự làm)

```swift
import Combine

final class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published private(set) var results: [String] = []

    private var bag = Set<AnyCancellable>()

    init() {
        $query
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .map { q in q.isEmpty ? [] : ["Result for \(q)"] }
            .assign(to: &$results)
    }
}
```

`@Published` là Publisher — SwiftUI tự subscribe khi view đọc `@ObservedObject`/`@StateObject`.

**Khi nào Combine trong banking?**
- Debounce input tra cứu STK/Beneficiary
- CombineLatest form fields → button `isEnabled`
- Bridge callback-based lib sang stream

### 2.2 `AsyncStream` — reactive kiểu async

Từ iOS 15+, có thể "reactive" bằng `AsyncSequence` — không cần Combine.

```swift
func rateStream() -> AsyncStream<Decimal> {
    AsyncStream { continuation in
        let task = Task {
            while !Task.isCancelled {
                let rate = await fetchRate()
                continuation.yield(rate)
                try? await Task.sleep(nanoseconds: 5_000_000_000)
            }
        }
        continuation.onTermination = { _ in task.cancel() }
    }
}

// Consume
Task {
    for await rate in rateStream() {
        await MainActor.run { self.rate = rate }
    }
}
```

Ưu điểm so với Combine:
- Không cần import Combine, không AnyCancellable
- Cancel tự nhiên qua Task
- Đọc code như for-loop, dễ hiểu

Banking dùng nhiều: FX rate live, notification stream, transaction updates từ WebSocket (mục 6.2).

---

## 3. Dependency Injection & Context

### 3.1 `.environmentObject()` — ContextProvider

Đã thấy ở Level 1. Nhớ:
- Provide 1 lần ở root
- Consume bằng `@EnvironmentObject`
- **Crash runtime** nếu thiếu

```swift
RootView()
    .environmentObject(session)
    .environmentObject(SessionLockService.shared)
```

### 3.2 Custom `EnvironmentKey` — inject giá trị đơn giản

Khi bạn muốn inject thứ **không phải ObservableObject** (Repository, config, theme):

```swift
private struct AccountRepoKey: EnvironmentKey {
    static let defaultValue: AccountRepository = MockAccountRepository()
}

extension EnvironmentValues {
    var accountRepo: AccountRepository {
        get { self[AccountRepoKey.self] }
        set { self[AccountRepoKey.self] = newValue }
    }
}

// Provide (test hoặc app):
DashboardView().environment(\.accountRepo, APIAccountRepository())

// Consume:
struct DashboardView: View {
    @Environment(\.accountRepo) private var accountRepo
    // ...
}
```

Tương đương `React.createContext(defaultValue)` + `useContext()`.

**Khi nào dùng thay `.environmentObject`?**
- Value type (struct)
- Không cần trigger re-render khi giá trị đổi
- Muốn có default value (không crash khi thiếu)

### 3.3 DI Container pattern

Repo đang dùng **constructor injection với default value** — DI đơn giản, không cần container:

```swift
init(
    accountRepo: AccountRepository = MockAccountRepository(),
    transferRepo: TransferRepository = MockTransferRepository()
) { /* ... */ }
```

Xem [`TransferViewModel.init`](../Nectar/Features/Transfers/Presentation/TransferViewModel.swift).

Khi app to hơn, dùng lightweight container:

```swift
final class AppContainer {
    lazy var accountRepo: AccountRepository = APIAccountRepository(client: apiClient)
    lazy var transferRepo: TransferRepository = APITransferRepository(client: apiClient)
    lazy var apiClient = APIClient.shared
}

// Provide qua environmentObject hoặc singleton
```

Xu hướng hiện đại: **Swift 5.9+ `@Observable` + `@Environment`** thay cho DI container phức tạp. Ngoài ra có lib: **Factory**, **Resolver**, **Swinject** — nhưng team nhỏ thường không cần.

**Interview:** "Vì sao không dùng singleton mọi nơi?" → Singleton khó test (không mock được), làm coupling tight, giấu dependency graph. DI cho phép mock trong `#Preview`, unit test.

---

## 4. Animation

### 4.1 `withAnimation {}` — implicit khi thay đổi state

```swift
@State private var expanded = false

Button("Toggle") {
    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
        expanded.toggle()
    }
}

if expanded {
    DetailPanel()
}
```

Mọi View có `expanded` phụ thuộc sẽ animate.

### 4.2 `.animation(value:)` — implicit gắn view cụ thể

```swift
Circle()
    .fill(BankColors.brand)
    .frame(width: expanded ? 200 : 80, height: expanded ? 200 : 80)
    .animation(.spring, value: expanded)
```

Ưu tiên `.animation(value:)` hơn `.animation(.spring)` không có `value:` (deprecated).

### 4.3 Các curve

```swift
.animation(.linear(duration: 0.2), value: x)
.animation(.easeInOut(duration: 0.3), value: x)
.animation(.spring(response: 0.4, dampingFraction: 0.6), value: x)
.animation(.interpolatingSpring(stiffness: 300, damping: 20), value: x)
.animation(.smooth, value: x)               // iOS 17+
```

Trong banking, dùng **spring** nhẹ cho card, sheet; **easeInOut** cho tab; hạn chế `linear` (thô).

### 4.4 Gestures + `@GestureState`

```swift
struct SwipeToConfirm: View {
    @GestureState private var dragX: CGFloat = 0
    var body: some View {
        Circle()
            .offset(x: dragX)
            .gesture(
                DragGesture()
                    .updating($dragX) { value, state, _ in
                        state = max(0, value.translation.width)
                    }
                    .onEnded { value in
                        if value.translation.width > 200 { /* confirm */ }
                    }
            )
    }
}
```

`@GestureState` = state chỉ tồn tại **trong khi gesture đang active**, tự reset khi gesture kết thúc — cực gọn.

Các gesture khác: `MagnificationGesture` (pinch-zoom), `RotationGesture`, `TapGesture(count:)`, `LongPressGesture`.

### 4.5 Phase Animator (iOS 17+) — chuỗi state animation

```swift
enum Phase: CaseIterable { case idle, expand, shrink }

Circle()
    .phaseAnimator(Phase.allCases) { view, phase in
        view.scaleEffect(phase == .expand ? 1.4 : phase == .shrink ? 0.8 : 1)
    } animation: { phase in
        .spring(duration: 0.5)
    }
```

Chạy tuần tự qua các phase — thay cho hàng chục `withAnimation` liên tiếp.

### 4.6 Keyframe Animation (iOS 17+) — animation phức tạp

```swift
Text("Success")
    .keyframeAnimator(initialValue: AnimValue()) { view, val in
        view
            .scaleEffect(val.scale)
            .rotationEffect(.degrees(val.rotation))
    } keyframes: { _ in
        KeyframeTrack(\.scale) {
            CubicKeyframe(1.3, duration: 0.2)
            CubicKeyframe(1.0, duration: 0.3)
        }
        KeyframeTrack(\.rotation) {
            SpringKeyframe(15, duration: 0.4)
            SpringKeyframe(0, duration: 0.6)
        }
    }
```

Tuyệt vời cho success animation sau chuyển tiền.

---

## 5. Custom Logic tái sử dụng

### 5.1 Custom `ObservableObject` — đóng gói state + logic

Đây là pattern chính trong repo. Mỗi VM đóng gói:
- State (`@Published`)
- Actions (methods)
- Dependencies (init inject)

```swift
@MainActor
final class OTPFlow: ObservableObject {
    @Published var code = ""
    @Published private(set) var status: Status = .idle
    private let expected: String
    private let onSuccess: () -> Void

    init(expected: String, onSuccess: @escaping () -> Void) {
        self.expected = expected
        self.onSuccess = onSuccess
    }

    func verify() {
        status = code == expected ? .valid : .invalid
        if status == .valid { onSuccess() }
    }
}
```

Tái sử dụng cho: login OTP, transfer OTP, password reset — tất cả share logic.

### 5.2 Custom `@propertyWrapper`

Tự viết property wrapper để đóng gói behavior:

```swift
@propertyWrapper
struct Trimmed {
    private var value: String = ""
    var wrappedValue: String {
        get { value }
        set { value = newValue.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
}

struct RecipientForm {
    @Trimmed var name: String = ""
}

form.name = "  Bảo   "
print(form.name)   // "Bảo"
```

Trong banking, có thể viết:
- `@Masked` cho STK / thẻ
- `@Digits` giữ chỉ số
- `@Currency` format tiền

`@AppStorage`, `@SceneStorage`, `@FocusState` đều là property wrapper của Apple.

### 5.3 Custom `ViewModifier` (đã đề cập Level 1)

Advanced: modifier có `@State`, `@Binding` để thêm behavior:

```swift
struct ShakeOnError: ViewModifier {
    let trigger: Bool
    @State private var offset: CGFloat = 0
    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .onChange(of: trigger) { _, _ in
                withAnimation(.default.repeatCount(3, autoreverses: true).speed(6)) {
                    offset = 10
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { offset = 0 }
            }
    }
}

extension View { func shakeOnError(_ trigger: Bool) -> some View { modifier(ShakeOnError(trigger: trigger)) } }
```

Dùng: `TextField(...).shakeOnError(loginFailed)`.

---

## 6. Networking & Realtime

### 6.1 `URLSession` với async/await

Ngày xưa dùng closure completion — nay dùng async:

```swift
let (data, response) = try await URLSession.shared.data(for: urlRequest)
guard let http = response as? HTTPURLResponse, 200...299 ~= http.statusCode else {
    throw AppError.network("HTTP error")
}
let decoded = try JSONDecoder().decode(Response.self, from: data)
```

Repo có [`APIClient`](../Nectar/Core/Network/APIClient.swift) implement:
- Bearer token attach từ Keychain
- Envelope decode (`code`, `body`, `message` giống PostPay)
- JWT refresh flow (401 → refresh → retry 1 lần)
- `actor` để đồng bộ hóa refresh token (chỉ 1 refresh chạy tại 1 thời điểm)

```swift
actor APIClient {
    private let session: URLSession
    private let baseURL: URL

    func post<B: Encodable, T: Decodable>(_ path: String, body: B, as type: T.Type) async throws -> T {
        // ...
    }

    private func request<T: Decodable>(..., retryCount: Int = 0) async throws -> T {
        // 401 -> refreshTokenIfNeeded() -> retry
    }
}
```

**Vì sao `actor`?** Đảm bảo state (token) truy cập tuần tự — tránh 2 request cùng lúc refresh 2 lần.

### 6.2 `URLSessionWebSocketTask` — WebSocket native

```swift
let task = URLSession.shared.webSocketTask(with: URL(string: "wss://api.bank.com/tx")!)
task.resume()

// Nhận message dạng async
Task {
    while task.state == .running {
        do {
            let message = try await task.receive()
            switch message {
            case .string(let text): handleTx(text)
            case .data(let data): handleBinary(data)
            @unknown default: break
            }
        } catch {
            break
        }
    }
}

// Gửi
try await task.send(.string("{\"cmd\":\"subscribe\"}"))
```

Banking dùng WebSocket cho: notification giao dịch realtime, chat CSKH, live FX board.

Kết hợp `AsyncStream` (mục 2.2) để expose cho ViewModel:

```swift
func transactionStream() -> AsyncStream<Transaction> {
    AsyncStream { continuation in
        // wrap WebSocket, yield khi có tx mới
    }
}
```

### 6.3 Certificate Pinning — `URLSessionDelegate`

Chống MITM: chỉ chấp nhận cert có public key khớp danh sách pin.

```swift
final class PinnedSessionDelegate: NSObject, URLSessionDelegate {
    let pinnedKeys: Set<Data>   // SHA-256 SubjectPublicKeyInfo

    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let trust = challenge.protectionSpace.serverTrust,
              let cert = SecTrustGetCertificateAtIndex(trust, 0),
              let key = SecCertificateCopyKey(cert),
              let raw = SecKeyCopyExternalRepresentation(key, nil) as Data?
        else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        let hash = SHA256.hash(data: raw)
        let hashData = Data(hash)
        if pinnedKeys.contains(hashData) {
            completionHandler(.useCredential, URLCredential(trust: trust))
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)  // reject
        }
    }
}

let config = URLSessionConfiguration.default
let session = URLSession(configuration: config, delegate: PinnedSessionDelegate(), delegateQueue: nil)
```

**Interview:** "Tại sao pinning quan trọng với banking?" → Ngăn attacker sniff traffic ngay cả khi cài cert giả lên thiết bị (rooted, corporate proxy). Đây là **bắt buộc** cho app ngân hàng ở nhiều thị trường (VN Circular 35, PSD2 EU).

---

## 7. Map

### 7.1 `MapKit` với SwiftUI (iOS 17+)

```swift
import MapKit

struct ATMMapView: View {
    @State private var camera: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: .init(latitude: 10.7769, longitude: 106.7009),
            span: .init(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    let atms: [ATM]

    var body: some View {
        Map(position: $camera) {
            ForEach(atms) { atm in
                Marker(atm.name, systemImage: "banknote", coordinate: atm.coord)
                    .tint(BankColors.brand)
            }
            if let route = suggestedRoute {
                MapPolyline(route.polyline).stroke(BankColors.brand, lineWidth: 4)
            }
            UserAnnotation()   // vị trí user
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
    }
}
```

Cần bật `NSLocationWhenInUseUsageDescription` trong Info.plist và request quyền qua `CLLocationManager`.

Ứng dụng banking: **tìm ATM/chi nhánh gần nhất**, tracking shipper thẻ, KYC location check.

### 7.2 `UIViewRepresentable` — bọc UIKit view

Với API cần thiết chưa có SwiftUI (hoặc iOS < 17), bọc `MKMapView`:

```swift
struct LegacyMapView: UIViewRepresentable {
    let atms: [ATM]

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        map.removeAnnotations(map.annotations)
        map.addAnnotations(atms.map { ATMAnnotation(atm: $0) })
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, MKMapViewDelegate { /* ... */ }
}
```

Cùng pattern áp dụng để bọc bất kỳ UIKit view nào: `PDFKit`, `WKWebView`, `AVPlayerViewController`, camera view của SDK KYC.

**Interview:** "Khác nhau `UIViewRepresentable` vs `UIViewControllerRepresentable`?" → Cùng ý tưởng, cái đầu bọc `UIView`, cái sau bọc `UIViewController` (khi cần lifecycle của VC, vd camera).

---

## 8. Bảo mật — banking-specific

Đây là phần **QUAN TRỌNG NHẤT** khi phỏng vấn banking. Học kỹ.

### 8.1 Keychain — lưu token/PIN

**Tuyệt đối không dùng `UserDefaults`** cho token, PIN, khóa mã hóa — vì `UserDefaults` lưu plaintext trong `~/Library/Preferences/*.plist`, ai jailbreak thiết bị hoặc lấy backup iTunes có thể đọc.

Keychain:
- Được OS bảo vệ, encrypt at rest
- Có accessibility level: `WhenUnlocked`, `AfterFirstUnlock`, `WhenPasscodeSet`...
- Có thể yêu cầu biometric để đọc (`SecAccessControl`)

Repo: [`KeychainService.swift`](../Nectar/Core/Storage/KeychainService.swift)

```swift
enum KeychainService {
    static func set(_ value: String, forKey key: String) {
        // ...
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(attributes as CFDictionary, nil)
    }

    static func get(forKey key: String) -> String? { /* ... */ }
    static func delete(forKey key: String) { /* ... */ }
}
```

`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` — token đọc được sau lần unlock đầu tiên (cho phép background fetch), không migrate qua thiết bị mới (chống restore backup).

### 8.2 `LocalAuthentication` — Face ID / Touch ID

Repo: [`BiometricAuthService.swift`](../Nectar/Core/Security/BiometricAuthService.swift)

```swift
func authenticate(reason: String) async -> Bool {
    let context = LAContext()
    context.localizedCancelTitle = "Dùng mật khẩu"
    return await withCheckedContinuation { continuation in
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
            continuation.resume(returning: success)
        }
    }
}
```

Info.plist bắt buộc có:
```xml
<key>NSFaceIDUsageDescription</key>
<string>Nectar dùng Face ID để bảo vệ giao dịch của bạn.</string>
```

**Policy:**
- `.deviceOwnerAuthenticationWithBiometrics` — chỉ Face ID / Touch ID
- `.deviceOwnerAuthentication` — biometric, fallback sang passcode thiết bị

**Best practice:** khi user tắt Face ID toàn cục hoặc thay đổi biometry (thêm face mới), `LAContext.evaluatedPolicyDomainState` sẽ đổi — banking nên **invalidate token** để tránh attacker thay biometric để chiếm quyền.

Xem thêm [`transferSubmit` trong `TransferViewModel`](../Nectar/Features/Transfers/Presentation/TransferViewModel.swift) — bắt buộc biometric trước khi submit.

### 8.3 Jailbreak / rooted detection

Detect device rooted để refuse cho phép app chạy hoặc cảnh báo:

```swift
enum JailbreakDetector {
    static var isJailbroken: Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        let paths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/"
        ]
        for path in paths where FileManager.default.fileExists(atPath: path) {
            return true
        }
        // Kiểm tra viết file ngoài sandbox
        let test = "/private/jailbreak_test.txt"
        do {
            try "test".write(toFile: test, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: test)
            return true   // viết được ngoài sandbox = jailbreak
        } catch {
            return false
        }
        #endif
    }
}
```

Trong `AppSession.bootstrap()`:
```swift
if JailbreakDetector.isJailbroken {
    route = .blocked   // hiện màn cảnh báo
    return
}
```

**Note:** không có detect nào hoàn hảo — attacker có thể hook. Nhưng vẫn là lớp phòng thủ cần thiết (defense in depth).

### 8.4 Screenshot / Screen recording protection

Ngăn screenshot màn nhạy cảm (balance, OTP):

```swift
struct BalanceView: View {
    var body: some View {
        Text("₫ 12,000,000")
            .privacySensitive()                              // iOS 15+
            .redacted(reason: isCaptured ? .placeholder : []) // manual
    }

    @Environment(\.isCaptured) private var isCaptured        // iOS 17+
}
```

Cách khác dùng `UIScreen.main.isCaptured` KVO (UIKit):

```swift
final class ScreenCaptureObserver: ObservableObject {
    @Published private(set) var isCaptured = false
    init() {
        NotificationCenter.default.addObserver(
            forName: UIScreen.capturedDidChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            self?.isCaptured = UIScreen.main.isCaptured
        }
    }
}
```

**iOS không cho block screenshot 100%** như Android FLAG_SECURE. Chiến thuật thực tế:
- Ẩn dữ liệu nhạy cảm (mask, redact) khi `isCaptured == true`
- Overlay `SecureField` (bug-ish) hoặc dùng `UITextField` với `isSecureTextEntry = true` để iOS tự đen ảnh
- Log/alert backend nếu detect recording

### 8.5 Background blur khi app inactive — `scenePhase`

Khi user swipe app switcher, iOS chụp preview → có thể lộ balance. Blur ngay khi inactive:

```swift
@main
struct NectarApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var showPrivacyOverlay = false

    var body: some Scene {
        WindowGroup {
            RootView()
                .overlay {
                    if showPrivacyOverlay {
                        BankColors.brand.ignoresSafeArea()
                            .overlay(Image(systemName: "lock.fill").font(.largeTitle).foregroundStyle(.white))
                    }
                }
                .onChange(of: scenePhase) { _, phase in
                    showPrivacyOverlay = phase != .active
                }
        }
    }
}
```

`scenePhase`:
- `.active` — app đang chạy foreground
- `.inactive` — chuyển state (call đến, control center, switcher preview)
- `.background` — đã ra background

Kết hợp với `SessionLockService` — [xem repo](../Nectar/Core/Security/SessionLockService.swift):

```swift
@MainActor
final class SessionLockService: ObservableObject {
    @Published private(set) var isLocked = false
    private let idleTimeout: TimeInterval = 5 * 60     // 5 phút

    func startMonitoring() { /* timer tick */ }
    func recordActivity() { lastActivity = Date() }
    func lockNow() { isLocked = true }
    func unlock() { isLocked = false; lastActivity = Date() }
}
```

Overlay giao diện lock: [`SessionLockOverlay.swift`](../Nectar/Shared/Components/SessionLockOverlay.swift) — user unlock bằng Face ID hoặc PIN.

### 8.6 Checklist tổng hợp (banking mandatory)

Xem đầy đủ ở [`security-checklist.md`](./security-checklist.md). Điểm cốt lõi:

- [x] Token/PIN lưu Keychain, không UserDefaults
- [x] Face ID / Touch ID confirm giao dịch nhạy cảm
- [x] Session idle lock 5 phút
- [x] Background blur khi inactive
- [x] Blur / redact dữ liệu khi `isCaptured`
- [x] Jailbreak detection (block hoặc cảnh báo)
- [ ] Certificate Pinning cho API production
- [x] JWT refresh flow, tự logout khi 401 hoặc envelope 205
- [x] Không log body chứa amount / STK
- [ ] Obfuscate code nhạy cảm (SwiftShield hoặc similar)
- [ ] Runtime anti-debug (`ptrace(PT_DENY_ATTACH)`) cho release

---

## Roadmap tự học Level 3 (sau khi vững Level 2)

- **Testing nâng cao:** snapshot tests, UI tests (XCUITest), stub network with URLProtocol
- **CI/CD:** Xcode Cloud, fastlane, TestFlight distribution
- **Monitoring:** Firebase Crashlytics, Sentry, custom analytics event schema
- **Modularization:** SwiftPM local packages, multi-module Xcode workspace
- **Concurrency deep-dive:** actor isolation, `Sendable`, structured concurrency edge cases
- **Accessibility & localization:** Dynamic Type, VoiceOver, RTL support, string catalogs

Khi bạn build lại `Nectar` từ đầu **không nhìn code**, giải thích được từng dòng, và pass được mock interview 3 vòng ([`mock-interview-guide.md`](./mock-interview-guide.md)) — bạn sẵn sàng cho mid-level SwiftUI ở banking.
