import Foundation

final class AppStorageService {
    static let shared = AppStorageService()

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let onboarding = "hasCompletedOnboarding"
        static let biometricEnabled = "biometricEnabled"
        static let balanceHidden = "balanceHidden"
        static let sessionToken = "sessionAccessToken"
        static let displayName = "userDisplayName"
    }

    var hasCompletedOnboarding: Bool {
        get { defaults.bool(forKey: Keys.onboarding) }
        set { defaults.set(newValue, forKey: Keys.onboarding) }
    }

    /// Session is Keychain-backed; this mirrors login state for quick checks.
    var isLoggedIn: Bool {
        get { KeychainService.get(forKey: Keys.sessionToken) != nil }
        set {
            if newValue {
                if KeychainService.get(forKey: Keys.sessionToken) == nil {
                    KeychainService.set(UUID().uuidString, forKey: Keys.sessionToken)
                }
            } else {
                KeychainService.delete(forKey: Keys.sessionToken)
            }
        }
    }

    var sessionToken: String? {
        KeychainService.get(forKey: Keys.sessionToken)
    }

    func createSession() -> String {
        let token = "tok_\(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(24))"
        KeychainService.set(token, forKey: Keys.sessionToken)
        return token
    }

    func clearSession() {
        KeychainService.delete(forKey: Keys.sessionToken)
    }

    var biometricEnabled: Bool {
        get { defaults.object(forKey: Keys.biometricEnabled) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.biometricEnabled) }
    }

    var balanceHidden: Bool {
        get { defaults.bool(forKey: Keys.balanceHidden) }
        set { defaults.set(newValue, forKey: Keys.balanceHidden) }
    }

    var userDisplayName: String {
        get { defaults.string(forKey: Keys.displayName) ?? MockBankAPI.customerName }
        set { defaults.set(newValue, forKey: Keys.displayName) }
    }
}
