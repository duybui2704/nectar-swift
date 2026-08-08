import SwiftUI

struct LoginView: View {
    private enum Field: Hashable, CaseIterable {
        case username, password
    }
    @EnvironmentObject private var session: AppSession
    @StateObject private var viewModel = LoginViewModel()
    @HotReloadObserver private var _hr
    @FocusState private var focusedField: Field?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Image("login")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: NectarMetrics.spacing.xs) {
                    Text("Get your groceries\nwith nectar")
                        .font(.system(size: NectarMetrics.font.largeTitle, weight: .semibold))
                        .foregroundStyle(NectarColors.navy)
                        .fixedSize(horizontal: false, vertical: true)

                    usernameField
                    passwordField

                    if case .error(let message) = viewModel.status {
                        Text(message)
                            .font(NectarTypography.caption)
                            .foregroundStyle(NectarColors.danger)
                    }

                    loginButton

                    Text("Or connect with social media")
                        .font(NectarTypography.body)
                        .foregroundStyle(NectarColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.top, NectarMetrics.spacing.sm)

                    HStack(spacing: NectarMetrics.spacing.sm) {
                        socialButton(
                            title: "Google",
                            icon: "ic_gg",
                            color: NectarColors.googleBlue
                        ) {
                            Task {
                                if let auth = await viewModel.continueWithSocial(provider: "google") {
                                    session.loginSucceeded(session: auth)
                                }
                            }
                        }
                        socialButton(
                            title: "Facebook",
                            icon: "ic_fb",
                            color: NectarColors.facebookBlue
                        ) {
                            Task {
                                if let auth = await viewModel.continueWithSocial(provider: "facebook") {
                                    session.loginSucceeded(session: auth)
                                }
                            }
                        }
                    }
                }
                .screenPadding()
                .padding(.top, NectarMetrics.spacing.md)
                .padding(.bottom, NectarMetrics.layout.bottomSafeExtra)
            }
        }
        .background(Color.white.ignoresSafeArea())
        .ignoresSafeArea(edges: .top)
        .scrollDismissesKeyboard(.interactively)
        .contentShape(Rectangle())
        .onTapGesture {
            focusedField = nil
        }
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                HStack(spacing: 12) {
                    Button {
                        moveFocus(delta: -1)
                    } label: {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .disabled(!canMoveFocus(delta: -1))

                    Button {
                        moveFocus(delta: 1)
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .disabled(!canMoveFocus(delta: 1))
                }
            }
        }
        .hotReload()
    }

    // MARK: - Fields

    private var usernameField: some View {
        underlineField(isActive: focusedField == .username) {
            HStack(spacing: NectarMetrics.spacing.xxs) {
                Image(systemName: "person")
                    .font(.system(size: NectarMetrics.font.textNormal, weight: .medium))
                    .foregroundStyle(NectarColors.textSecondary)
                    .frame(width: NectarMetrics.s(22), alignment: .center)

                TextField("Username", text: $viewModel.username)
                    .textContentType(.username)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(NectarTypography.caption)
                    .foregroundStyle(NectarColors.navy)
                    .focused($focusedField, equals: .username)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .password }
            }
        } onTap: {
            focusedField = .username
        }
    }

    private var passwordField: some View {
        underlineField(isActive: focusedField == .password) {
            HStack(spacing: NectarMetrics.spacing.xxs) {
                Image(systemName: "lock")
                    .font(.system(size: NectarMetrics.s(14), weight: .medium))
                    .foregroundStyle(NectarColors.textSecondary)
                    .frame(width: NectarMetrics.s(22), alignment: .center)

                SecureField("Password", text: $viewModel.password)
                    .textContentType(.password)
                    .font(NectarTypography.caption)
                    .foregroundStyle(NectarColors.navy)
                    .focused($focusedField, equals: .password)
                    .submitLabel(.go)
                    .onSubmit {
                        Task { await submitLogin() }
                    }
            }
        } onTap: {
            focusedField = .password
        }
    }

    private func underlineField<Content: View>(
        isActive: Bool,
        @ViewBuilder content: () -> Content,
        onTap: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 4) {
            content()
                .frame(height: NectarMetrics.s(36), alignment: .center)

            Rectangle()
                .fill(isActive ? NectarColors.green : NectarColors.border)
                .frame(height: 1)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    // MARK: - Focus navigation

    private func canMoveFocus(delta: Int) -> Bool {
        guard let current = focusedField,
              let index = Field.allCases.firstIndex(of: current) else { return false }
        return Field.allCases.indices.contains(index + delta)
    }

    private func moveFocus(delta: Int) {
        guard let current = focusedField,
              let index = Field.allCases.firstIndex(of: current) else { return }
        let next = index + delta
        guard Field.allCases.indices.contains(next) else { return }
        focusedField = Field.allCases[next]
    }

    // MARK: - Buttons

    private var loginButton: some View {
        Button {
            focusedField = nil
            Task { await submitLogin() }
        } label: {
            Group {
                if viewModel.status == .loading {
                    ProgressView().tint(.white)
                } else {
                    Text("Log In")
                        .font(NectarTypography.button)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: NectarMetrics.button.primaryHeight)
            .foregroundStyle(.white)
            .background(NectarColors.green)
            .clipShape(RoundedRectangle(cornerRadius: NectarMetrics.button.cornerRadius))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.status == .loading)
    }

    private func socialButton(
        title: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                HStack {
                    Image(icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: NectarMetrics.s(18), height: NectarMetrics.s(18))
                    Spacer()
                }

                if viewModel.status == .loading {
                    ProgressView().tint(.white)
                } else {
                    Text(title)
                        .font(NectarTypography.headline)
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, NectarMetrics.spacing.lg)
            .frame(maxWidth: .infinity)
            .frame(height: NectarMetrics.button.primaryHeight)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: NectarMetrics.button.cornerRadius))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.status == .loading)
    }

    private func submitLogin() async {
        if let auth = await viewModel.login() {
            session.loginSucceeded(session: auth)
        }
    }
}
