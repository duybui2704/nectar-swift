# Debug Nectar: OSLog + Proxyman + Xcode Breakpoints

Hướng dẫn debug network / crash / UI cho app Nectar. Repo **đã cấu hình sẵn** phần code + shared breakpoints — bạn chỉ cần cài Proxyman và biết filter log.

---

## 0. Đã có sẵn trong repo

| Thứ | Vị trí | Vai trò |
|-----|--------|---------|
| OSLog wrapper | `Nectar/Core/DevTools/NectarLog.swift` | `NectarLog.log(_:title:level:)` → OSLog + print DEBUG |
| Network log | `Nectar/Core/Network/NetworkLogger.swift` | Request/response → category `Network` |
| Bootstrap | `Nectar/Core/DevTools/DebugToolsBootstrap.swift` | Smoke log khi app start |
| Shared BP | `Nectar.xcodeproj/xcshareddata/xcdebugger/Breakpoints_v2.xcbkptlist` | Exception / Swift error / Auto Layout / main-thread |
| API client | `Nectar/Core/Network/APIClient.swift` | `URLSession` **không certificate pinning** → Proxyman MITM OK |

**Không pin cert** = Proxyman decode HTTPS được sau khi trust CA. Khi sau này thêm pinning, phải thêm DEBUG bypass riêng.

---

## 1. OSLog — cách dùng trong code

### API

```swift
NectarLog.log("decoded 12 items")
// → Nectar log =>> decoded 12 items

NectarLog.log("decoded 12 items", title: "Home")
// → Nectar log Home =>> decoded 12 items

NectarLog.log("HTTP 500", title: "Network", level: .error)
```

| Param | Mặc định | Ý nghĩa |
|-------|----------|---------|
| `message` | — | Nội dung |
| `title` | `nil` → category `App` | Category OSLog + ghép sau `Nectar log` |
| `level` | `.debug` | `.debug` / `.info` / `.error` / `.fault` |

### Mapping OSLog

| | |
|--|--|
| **subsystem** | `com.example.Nectar` (`PRODUCT_BUNDLE_IDENTIFIER`) |
| **category** | = `title` (hoặc `App`) |
| **prefix text** | luôn có `Nectar log … =>>` để filter nhanh |

### Filter trong Xcode Console

1. ⌘R app (Debug).
2. Mở Debug area → Console.
3. Ô filter gõ:
   - `Nectar log` — mọi log app
   - `Nectar log Network` — chỉ API
   - `Nectar log Home` — home catalog
4. Bật **All Output** (không chỉ Debugger).
5. Nếu không thấy OSLog: menu Console → bật metadata / dùng filter `subsystem:com.example.Nectar`.

### Filter trong Console.app (macOS)

1. Mở **Console.app** → chọn Simulator / device.
2. Action → Include Info Messages + Include Debug Messages.
3. Search:
   - `subsystem:com.example.Nectar`
   - hoặc `category:Network`
   - hoặc text `Nectar log`

### Khi nào dùng level nào

| Level | Dùng cho |
|-------|----------|
| `.debug` | Decode count, nhánh tạm |
| `.info` | Request/response OK, lifecycle |
| `.error` | HTTP fail, decode fail, catch |
| `.fault` | Trạng thái “không thể tiếp tục” (hiếm) |

NetworkLogger đã map sẵn: response OK → `.info`, lỗi/HTTP≠2xx → `.error`.

---

## 2. Proxyman — bắt HTTPS Printerval

App gọi các host:

- `customer-service.printerval.com`
- `order-service.printerval.com`
- `variant-service.printerval.com`
- `printerval.com`

### A. Simulator (nhanh nhất)

1. Cài [Proxyman](https://proxyman.io/) → mở app.
2. Menu **Certificate** → **Install Certificate on iOS** → **Simulators…** → Install & Trust.
3. **Certificate** → **Install Certificate on this Mac** (nếu chưa) → Keychain Trust = **Always Trust**.
4. **Tools** → **SSL Proxying List** → Add:
   - `*.printerval.com`
   - `printerval.com`
5. ⌘R Nectar từ Xcode.
6. Trong Proxyman filter: `printerval` — sẽ thấy `GET seller/spotlight`, `today-big-deals`, …

### B. Device thật

1. iPhone cùng Wi‑Fi với Mac.
2. Proxyman → **Certificate** → **Install Certificate on iOS** → **Physical Devices…** → làm theo wizard (Settings → Profile → Trust).
3. iOS **Settings → Wi‑Fi → (i) → Configure Proxy → Manual** → IP Mac + port Proxyman (thường `9090`).
4. Bật SSL Proxying `*.printerval.com` như trên.
5. Chạy app từ Xcode lên device.

### C. Checklist khi Proxyman “không thấy request”

| Triệu chứng | Cách xử lý |
|-------------|------------|
| Không có request nào | Proxyman chưa set làm proxy / Simulator chưa install cert |
| Có request nhưng `SSL Error` / tunnel | Chưa trust CA trên Sim/Mac; hoặc domain chưa nằm trong SSL Proxying List |
| Chỉ thấy `/` CONNECT | SSL Proxying chưa bật cho host đó |
| App báo mất mạng | Tắt proxy / bỏ Physical Device proxy khi không dùng |
| Body binary / encrypted | Domain chưa enable SSL Proxying |

### D. Kết hợp với OSLog

1. Proxyman = **wire** (headers, body thật, timing).
2. `Nectar log Network` = **app thấy gì** sau `URLSession` (đã redact `Authorization`).
3. Nếu Proxyman có body nhưng mapper ra `[]` → lỗi **parse** (xem `HomeDTOMapper` / `ProductDTOMapper`), không phải network.

### E. Không làm gì trong code?

Đúng — hiện **không cần** Atlantis / custom `URLSessionDelegate`.  
`DebugToolsBootstrap` chỉ in nhắc lúc launch. Khi thêm certificate pinning sau này, cập nhật doc này + thêm `#if DEBUG` bypass.

---

## 3. Xcode Breakpoints

### Shared breakpoints (đã commit)

Mở **Breakpoint Navigator** (`⌘8`). Bạn sẽ thấy (shared):

| Breakpoint | Mặc định | Khi nào dùng |
|------------|----------|--------------|
| Exception (ObjC) | ON | Crash `NSException` |
| Swift Error | ON (log + continue) | Mọi `throw` — Console: `Nectar BP =>> Swift error…` |
| `UIViewAlertForUnsatisfiableConstraints` | ON (log + continue) | Constraint conflict |
| `UIView.animate` off main thread | ON (stop) | UI update sai thread |
| `NSURLSession dataTask…` | OFF | Bật tạm khi muốn pause mỗi network create |

**Share / unshare:** right-click breakpoint → Share Breakpoint (file nằm dưới `xcshareddata/xcdebugger/`).

### Thêm breakpoint cho Nectar (khuyến nghị)

#### 1) Dừng khi API fail (file breakpoint)

1. Mở `APIClient.swift`.
2. Click gutter tại dòng `throw AppError.network(...)` hoặc `throw AppError.unauthorized`.
3. Right-click chấm xanh → **Edit Breakpoint…**:
   - Action → **Log Message**: `Nectar BP =>> APIClient throw %H`
   - (tuỳ chọn) Debugger Command: `po error`
   - ✅ Automatically continue (nếu chỉ muốn log)

#### 2) Dừng khi seller spotlight rỗng

Trong `HomeRepository` case `.sellers`:

- Condition: `sellers.isEmpty`
- Log: `Nectar BP =>> seller spotlight empty`

#### 3) Symbolic nhanh (UI)

Breakpoint Navigator → `+` → **Symbolic Breakpoint**:

- Symbol: `UIViewAlertForUnsatisfiableConstraints` (đã có sẵn shared)

#### 4) Runtime Issue / Main Thread Checker

Scheme → Run → Diagnostics:

- ✅ Main Thread Checker
- ✅ API Misuse / Guard Malloc (khi nghi memory)

### LLDB hữu ích khi đang dừng

```lldb
po error
po String(data: data, encoding: .utf8)
bt
thread info
```

Expression Swift:

```lldb
e -l swift -- import Nectar
```

---

## 4. Workflow debug thực tế

### Case: Home không có Seller Spotlight

```
1. Xcode filter: Nectar log Home
   → có "🏪 seller spotlight: 0"?
2. Filter: Nectar log Network
   → có REQUEST seller/spotlight? status?
3. Proxyman → mở request → xem JSON result
4. Breakpoint HomeDTOMapper.sellerSpotlight nếu JSON lệch key
```

### Case: Product Detail trắng / lỗi

```
1. Nectar log Product
2. Proxyman filter product/{id}
3. Swift Error BP → xem throw từ ProductDTOMapper
```

### Case: UI nhảy / constraint vàng trong console

```
1. Shared BP Unsatisfiable Constraints đã log "Nectar BP =>>"
2. Debug View Hierarchy (Debug → View Debugging)
```

---

## 5. Cheat-sheet filter

| Mục tiêu | Filter |
|----------|--------|
| Mọi log Nectar | `Nectar log` |
| API | `Nectar log Network` |
| Home | `Nectar log Home` |
| Breakpoint actions | `Nectar BP` |
| Console.app subsystem | `subsystem:com.example.Nectar` |
| Proxyman hosts | `printerval` |

---

## 6. Bảo mật / Release

- `NetworkLogger.isEnabled` = **DEBUG only** (không dump body API ra log Release).
- `NectarLog` vẫn ghi OSLog ở Release với level tương ứng — **đừng** log token/PII. Header `Authorization` đã redact trong `NetworkLogger`.
- Proxyman chỉ dùng máy dev; không commit proxy config vào scheme Production.

---

## 7. Liên kết

- Luồng API: [api-flow.md](./api-flow.md)
- Hot reload: [hot-reload.md](./hot-reload.md)
- Instruments: [instruments-notes.md](./instruments-notes.md)
- Security roadmap (pinning): [security-checklist.md](./security-checklist.md)
