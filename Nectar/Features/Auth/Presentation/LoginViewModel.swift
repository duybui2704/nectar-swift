import Foundation
import Combine

@MainActor
final class LoginViewModel: ObservableObject {
    enum Status: Equatable {
        case idle
        case loading
        case error(String)
    }

    @Published var username = "demo"
    @Published var password = ""
    @Published var status: Status = .idle
    @Published var biometricLabel = "Face ID"

    private let biometric: BiometricAuthService
    private let storage: AppStorageService

    init(
        biometric: BiometricAuthService? = nil,
        storage: AppStorageService = .shared
    ) {
        self.biometric = biometric ?? .shared
        self.storage = storage
        biometricLabel = self.biometric.biometryTypeName
    }

    var canUseBiometrics: Bool {
        storage.biometricEnabled && biometric.canUseBiometrics
    }

    func loginWithPassword() async -> Bool {
        status = .loading
        await MockNectarAPI.delay(500)
        guard username.lowercased() == "demo", password == "123456" else {
            status = .error("Sai tên đăng nhập hoặc mật khẩu. Demo: demo / 123456")
            return false
        }
        status = .idle
        return true
    }

    func loginWithBiometrics() async -> Bool {
        status = .loading
        let ok = await biometric.authenticate(reason: "Đăng nhập vào Nectar Starter")
        if ok {
            status = .idle
            return true
        }
        status = .error("Xác thực \(biometricLabel) thất bại.")
        return false
    }
}
