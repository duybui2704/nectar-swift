import Foundation

protocol AuthProviding: AnyObject {
    func login(username: String, password: String) async throws -> AuthSession
}

@MainActor
final class AuthRepository: AuthProviding {
    static let shared = AuthRepository()

    func login(username: String, password: String) async throws -> AuthSession {
        let email = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let data = try await PrintervalAPI.login(email: email, password: password)
        let session = try AuthDTOMapper.session(from: data)
        NectarLog.log(
            "Login OK — user: \(session.displayName) id: \(session.customerId ?? "-")",
            title: "Auth",
            level: .info
        )
        return session
    }
}
