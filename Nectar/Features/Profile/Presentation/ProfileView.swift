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
                            .fill(NectarColors.brandSoft)
                            .frame(width: 52, height: 52)
                            .overlay(
                                Text(String(session.userDisplayName.prefix(1)))
                                    .font(NectarTypography.title)
                                    .foregroundStyle(NectarColors.brand)
                            )
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.userDisplayName).font(NectarTypography.headline)
                            Text(MockNectarAPI.phoneMasked)
                                .font(NectarTypography.caption)
                                .foregroundStyle(NectarColors.textSecondary)
                            if let token = session.sessionToken {
                                Text("Session · \(token.prefix(12))…")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(NectarColors.textSecondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Orders & delivery") {
                    NavigationLink {
                        PlaceholderFeatureView(
                            title: "My Orders",
                            message: "Track past and current grocery orders."
                        )
                    } label: {
                        Label("My Orders", systemImage: "bag")
                    }
                    NavigationLink {
                        PlaceholderFeatureView(
                            title: "Delivery Address",
                            message: "Manage where your orders are delivered."
                        )
                    } label: {
                        Label("Delivery Address", systemImage: "mappin.and.ellipse")
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

                Section("More") {
                    ForEach(0..<8, id: \.self) { index in
                        Text("Setting \(index + 1)")
                    }
                }
            }
            .hidesTabBarOnScroll()
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: 72)
            }
            .navigationTitle("Account")
        }
    }
}
