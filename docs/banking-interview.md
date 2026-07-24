# Câu hỏi phỏng vấn iOS Banking (gợi ý trả lời bằng project này)

## Kiến trúc

**Q: Bạn tổ chức code mobile banking thế nào?**  
A: Feature-first Clean Architecture — `Domain` (models + protocols), `Data` (mock/API), `Presentation` (View + ViewModel). Map từ RN: screen + Zustand + `api.ts` → View + ViewModel + Repository.

**Q: Vì sao không dùng `Double` cho tiền?**  
A: Sai số floating-point. Dùng `Decimal` + `NumberFormatter` (`MoneyFormatter`).

## Bảo mật

**Q: Face ID hoạt động ra sao?**  
A: `LocalAuthentication` → `evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics)`. Có fallback passcode. Info.plist: `NSFaceIDUsageDescription`.

**Q: Session / token nên lưu đâu?**  
A: Keychain, không phải UserDefaults. Repo này: `KeychainService` + `AppStorageService.createSession()`; flag onboarding/biometric vẫn UserDefaults.

**Q: Che số tài khoản?**  
A: Luôn mask (`**** 4821`) trên UI list; full number chỉ khi user xác thực lại.

## Networking & state

**Q: Loading / error / empty?**  
A: `Status` enum trên ViewModel; UI `ProgressView`, message lỗi, `EmptyStateView`.

**Q: Chuyển khoản xử lý thế nào?**  
A: Form → validate (số dư, amount > 0, hạn mức) → màn confirm → submit → reference id. Không submit thẳng từ form.

## SwiftUI

**Q: `@StateObject` vs `@ObservedObject`?**  
A: Owner tạo ViewModel dùng `@StateObject`; nhận từ ngoài dùng `@ObservedObject` / `@EnvironmentObject`.

**Q: MainActor?**  
A: ViewModel `@MainActor` để update UI an toàn sau async.

## Behavioral / domain banking

- Offline / timeout transfer?
- Idempotency khi user bấm gửi 2 lần?
- OTP / soft token step?
- Accessibility số tiền cho VoiceOver?

Chuẩn bị 2–3 câu trả lời ngắn gắn với code bạn đã viết trong repo này.
