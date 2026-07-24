import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var session: AppSession
    @State private var biometricEnabled = AppStorageService.shared.biometricEnabled
    private let biometric = BiometricAuthService.shared

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(BankColors.brandSoft)
                            .frame(width: 52, height: 52)
                            .overlay(
                                Text(String(session.userDisplayName.prefix(1)))
                                    .font(BankTypography.title)
                                    .foregroundStyle(BankColors.brand)
                            )
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.userDisplayName).font(BankTypography.headline)
                            Text(MockBankAPI.phoneMasked)
                                .font(BankTypography.caption)
                                .foregroundStyle(BankColors.textSecondary)
                            if let token = session.sessionToken {
                                Text("Session · \(token.prefix(12))…")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(BankColors.textSecondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Ví & ngân hàng") {
                    NavigationLink {
                        PlaceholderFeatureView(
                            title: "Quản lý ví",
                            message: "Danh sách ví / số dư — map từ getAccountList PostPay."
                        )
                    } label: {
                        Label("Quản lý ví", systemImage: "wallet.pass")
                    }
                    NavigationLink {
                        PlaceholderFeatureView(
                            title: "Ngân hàng liên kết",
                            message: "Link bank Napas — map từ getBankLinkList PostPay."
                        )
                    } label: {
                        Label("Ngân hàng liên kết", systemImage: "building.columns")
                    }
                }

                Section("Bảo mật") {
                    Toggle("Đăng nhập \(biometric.biometryTypeName)", isOn: $biometricEnabled)
                        .onChange(of: biometricEnabled) { _, newValue in
                            AppStorageService.shared.biometricEnabled = newValue
                        }
                    NavigationLink {
                        PlaceholderFeatureView(
                            title: "Đổi mật khẩu",
                            message: "Sẽ nối API change password / forgetPwd của PostPay."
                        )
                    } label: {
                        Label("Đổi mật khẩu", systemImage: "lock.rotation")
                    }
                    NavigationLink {
                        PlaceholderFeatureView(
                            title: "Mã PIN",
                            message: "PIN / Smart OTP — bước bảo mật nâng cao sau core flow."
                        )
                    } label: {
                        Label("Cài đặt PIN", systemImage: "lock.fill")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        session.logout()
                    } label: {
                        Label("Đăng xuất", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Tài khoản")
        }
    }
}
