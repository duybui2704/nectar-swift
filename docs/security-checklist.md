# Security Checklist — Nectar

## Đã implement

- [x] Session token trong **Keychain** (`KeychainService`)
- [x] Face ID login + transfer confirm (`BiometricAuthService`)
- [x] OTP step-up trước submit transfer
- [x] Session idle lock 5 phút (`SessionLockService`)
- [x] PIN fallback demo (`PINService`, default `000000`)
- [x] Masked account numbers trên UI (`**** 4821`)
- [x] `NSFaceIDUsageDescription` trong Info.plist
- [x] Logout clear Keychain (`AppSession.logout`)

## Chưa / roadmap

- [ ] Certificate pinning
- [ ] Jailbreak / debugger detection
- [ ] Không screenshot màn OTP (iOS secure field)
- [ ] Rate limit login attempts
- [ ] Audit log server-side

## Không làm (demo)

- Không lưu password thật
- Không gửi PII lên server thật
- PIN hash demo-only — production cần Keychain + Secure Enclave

## Test nhanh

1. Login → kill app → mở lại → vẫn logged in (Keychain)
2. Logout → token cleared
3. Đợi 5 phút idle → session lock overlay
4. PIN `000000` hoặc Face ID → unlock
