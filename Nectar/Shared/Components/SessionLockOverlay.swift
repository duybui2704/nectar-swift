import SwiftUI

struct SessionLockOverlay: View {
    @ObservedObject var lockService: SessionLockService
    let onUnlockBiometric: () async -> Bool
    let onUnlockPIN: (String) -> Bool
    let onForceLogout: () -> Void

    @State private var pin = ""
    @State private var errorMessage: String?

    var body: some View {
        if lockService.isLocked {
            ZStack {
                Color.black.opacity(0.92).ignoresSafeArea()
                VStack(spacing: 20) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.white)
                    Text("Phiên đã khóa")
                        .font(BankTypography.title)
                        .foregroundStyle(.white)
                    Text("Không hoạt động 5 phút. Xác thực lại để tiếp tục.")
                        .font(BankTypography.caption)
                        .foregroundStyle(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    Button {
                        Task {
                            if await onUnlockBiometric() {
                                lockService.unlock()
                                errorMessage = nil
                            } else {
                                errorMessage = "Xác thực sinh trắc học thất bại."
                            }
                        }
                    } label: {
                        Label("Mở khóa bằng Face ID", systemImage: "faceid")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(BankColors.brand)
                    .padding(.horizontal, 32)

                    SecureField("PIN 6 số (demo: 000000)", text: $pin)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(BankColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 32)
                        .onChange(of: pin) { _, v in
                            let digits = v.filter(\.isNumber)
                            pin = String(digits.prefix(6))
                            if pin.count == 6 {
                                if onUnlockPIN(pin) {
                                    lockService.unlock()
                                    pin = ""
                                    errorMessage = nil
                                } else {
                                    errorMessage = "PIN không đúng."
                                    pin = ""
                                }
                            }
                        }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(BankTypography.caption)
                            .foregroundStyle(BankColors.danger)
                    }

                    Button("Đăng xuất", role: .destructive) {
                        onForceLogout()
                        lockService.unlock()
                    }
                    .padding(.top, 8)
                }
            }
            .transition(.opacity)
        }
    }
}
