import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var router: AppRouter
    @State private var biometricEnabled = AppStorageService.shared.biometricEnabled
    private let biometric = BiometricAuthService.shared

    var body: some View {
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
                NavigationLink(value: AppDestination.orders) {
                    Label("My Orders", systemImage: "bag")
                }
                NavigationLink(value: AppDestination.deliveryAddress) {
                    Label("Delivery Address", systemImage: "mappin.and.ellipse")
                }
            }

            Section("Bảo mật") {
                Toggle("Đăng nhập \(biometric.biometryTypeName)", isOn: $biometricEnabled)
                    .onChange(of: biometricEnabled) { _, newValue in
                        AppStorageService.shared.biometricEnabled = newValue
                    }
                NavigationLink(value: AppDestination.changePassword) {
                    Label("Đổi mật khẩu", systemImage: "lock.rotation")
                }
                NavigationLink(value: AppDestination.pinSettings) {
                    Label("Cài đặt PIN", systemImage: "lock.fill")
                }
            }

            Section {
                Button(role: .destructive) {
                    router.reset()
                    session.logout()
                } label: {
                    Label("Đăng xuất", systemImage: "rectangle.portrait.and.arrow.right")
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
