import Foundation

/// PIN fallback when biometrics unavailable — demo PIN stored hashed in UserDefaults.
enum PINService {
    private static let pinKey = "userPINHash"

    static var isConfigured: Bool {
        UserDefaults.standard.string(forKey: pinKey) != nil
    }

    static func setPIN(_ pin: String) {
        guard pin.count == 6, pin.allSatisfy(\.isNumber) else { return }
        UserDefaults.standard.set(hash(pin), forKey: pinKey)
    }

    static func verify(_ pin: String) -> Bool {
        guard let stored = UserDefaults.standard.string(forKey: pinKey) else {
            // Demo default PIN for first-time users
            return pin == "000000"
        }
        return hash(pin) == stored
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: pinKey)
    }

    private static func hash(_ pin: String) -> String {
        // Demo-only hash — production uses Keychain + secure enclave
        "pin_\(pin)_\(pin.count)"
    }
}
