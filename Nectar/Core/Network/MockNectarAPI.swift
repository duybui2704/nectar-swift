import Foundation

/// Offline mock API — interview-safe, no secrets / real PII.
enum MockNectarAPI {
    static let customerName = "Nguyễn Văn A"
    static let phoneMasked = "090****321"

    static func delay(_ ms: UInt64 = 450) async {
        try? await Task.sleep(nanoseconds: ms * 1_000_000)
    }

    @MainActor
    static var accounts: [AppAccount] { MockNectarStore.shared.accounts }

    @MainActor
    static var cards: [AppCard] { MockNectarStore.shared.cards }

    @MainActor
    static var beneficiaries: [Beneficiary] { MockNectarStore.shared.beneficiaries }

    @MainActor
    static func transactions(accountId: String) -> [Transaction] {
        MockNectarStore.shared.transactions(accountId: accountId)
    }
}
