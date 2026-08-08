import Foundation
import Combine

/// App-wide session (auth + onboarding). Token stored in Keychain.
@MainActor
final class AppSession: ObservableObject {
    enum Route {
        case splash
        case onboarding
        case login
        case main
    }

    @Published private(set) var route: Route = .splash
    @Published private(set) var userDisplayName: String
    @Published private(set) var sessionToken: String?

    private let storage: AppStorageService

    init(storage: AppStorageService = .shared) {
        self.storage = storage
        self.userDisplayName = storage.userDisplayName
        self.sessionToken = storage.sessionToken
    }

    func bootstrap() async {
        Task {
            await AppBootstrap.prefetchLaunchAPIs()
        }

        try? await Task.sleep(nanoseconds: 1_200_000_000)

        if !storage.hasCompletedOnboarding {
            route = .onboarding
        } else if storage.isLoggedIn {
            sessionToken = storage.sessionToken
            userDisplayName = storage.userDisplayName
            route = .main
        } else {
            route = .login
        }
    }

    func completeOnboarding() {
        storage.hasCompletedOnboarding = true
        route = .login
    }

    /// Đăng nhập thành công — lưu token API (không tạo token giả).
    func loginSucceeded(session: AuthSession) {
        userDisplayName = session.displayName
        storage.userDisplayName = session.displayName
        storage.saveSession(token: session.token)
        sessionToken = session.token
        route = .main
    }

    func logout() {
        storage.clearSession()
        sessionToken = nil
        route = .login
    }
}
