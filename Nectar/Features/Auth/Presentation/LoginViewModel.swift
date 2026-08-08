import Foundation
import Combine

@MainActor
final class LoginViewModel: ObservableObject {
    enum Status: Equatable {
        case idle
        case loading
        case error(String)
    }

    /// Prefill DEBUG credentials (curl test account).
    @Published var username = "test1@gmail.com"
    @Published var password = "123456"
    @Published var status: Status = .idle

    private let auth: AuthProviding
    
    init(auth: AuthProviding? = nil) {
        self.auth = auth ?? AuthRepository.shared
    }

    /// Gọi `POST customer/login`. Thành công → `AuthSession` (token + displayName).
    func login() async -> AuthSession? {
        status = .loading

        let user = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !user.isEmpty else {
            status = .error("Enter your username.")
            return nil
        }
        guard !password.isEmpty else {
            status = .error("Enter your password.")
            return nil
        }

        do {
            let session = try await auth.login(username: user, password: password)
            status = .idle
            return session
        } catch let error as AppError {
            status = .error(error.errorDescription ?? "Login failed.")
            return nil
        } catch {
            status = .error(error.localizedDescription)
            return nil
        }
    }

    func continueWithSocial(provider: String) async -> AuthSession? {
        status = .loading
        await MockNectarAPI.delay(500)
        status = .error("\(provider.capitalized) login chưa hỗ trợ. Dùng username / password.")
        return nil
    }
}
