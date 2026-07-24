import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var session: AppSession
    @StateObject private var viewModel = LoginViewModel()
    @HotReloadObserver private var _hr

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [BankColors.brand, BankColors.navySoft],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()
                VStack(spacing: 8) {
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.white)
                    Text("Nectar")
                        .font(BankTypography.largeTitle)
                        .foregroundStyle(.white)
                    Text("Ví & chuyển tiền an toàn")
                        .font(BankTypography.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }

                VStack(spacing: 14) {
                    TextField("Tên đăng nhập", text: $viewModel.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding()
                        .background(BankColors.inputBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                    SecureField("Mật khẩu", text: $viewModel.password)
                        .padding()
                        .background(BankColors.inputBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14))

                    if case .error(let message) = viewModel.status {
                        Text(message)
                            .font(BankTypography.caption)
                            .foregroundStyle(BankColors.danger)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        Task {
                            if await viewModel.loginWithPassword() {
                                session.loginSucceeded(displayName: MockBankAPI.customerName)
                            }
                        }
                    } label: {
                        Group {
                            if viewModel.status == .loading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Đăng nhập")
                                    .font(BankTypography.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                    .background(BankColors.brand)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .disabled(viewModel.status == .loading)

                    if viewModel.canUseBiometrics {
                        Button {
                            Task {
                                if await viewModel.loginWithBiometrics() {
                                    session.loginSucceeded(displayName: MockBankAPI.customerName)
                                }
                            }
                        } label: {
                            Label("Đăng nhập bằng \(viewModel.biometricLabel)", systemImage: "faceid")
                                .font(BankTypography.headline)
                                .foregroundStyle(BankColors.brand)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(20)
                .background(BankColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: Color(hex: 0x1D4F91).opacity(0.25), radius: 16, y: 8)
                .padding(.horizontal, 20)

                Text("Demo: demo / 123456")
                    .font(BankTypography.caption)
                    .foregroundStyle(.white.opacity(0.7))

                Spacer()
            }
        }
        .hotReload()
    }
}
