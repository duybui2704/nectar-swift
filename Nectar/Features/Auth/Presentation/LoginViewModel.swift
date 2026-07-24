import Foundation
import Combine

@MainActor
final class LoginViewModel: ObservableObject {
    enum Status: Equatable {
        case idle
        case loading
        case error(String)
    }

    @Published var phoneNumber = ""
    @Published var password = ""
    @Published var countryCode = "+84"
    @Published var status: Status = .idle

    /// Demo credentials: any phone ≥ 8 digits + password `123456`
    func login() async -> Bool {
        status = .loading
        await MockNectarAPI.delay(500)

        let digits = phoneNumber.filter(\.isNumber)
        guard digits.count >= 8 else {
            status = .error("Enter a valid phone number.")
            return false
        }
        guard password == "123456" else {
            status = .error("Wrong password. Demo: 123456")
            return false
        }

        status = .idle
        return true
    }

    func continueWithSocial(provider: String) async -> Bool {
        status = .loading
        await MockNectarAPI.delay(500)
        status = .idle
        return true
    }
}
