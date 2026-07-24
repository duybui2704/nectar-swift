import Foundation

/// Offline mock bank backend — interview-safe, no secrets / real PII.
enum MockBankAPI {
    static let customerName = "Nguyễn Văn A"
    static let phoneMasked = "090****321"

    static func delay(_ ms: UInt64 = 450) async {
        try? await Task.sleep(nanoseconds: ms * 1_000_000)
    }

    @MainActor
    static var accounts: [BankAccount] { MockBankStore.shared.accounts }

    @MainActor
    static var cards: [BankCard] { MockBankStore.shared.cards }

    @MainActor
    static var beneficiaries: [Beneficiary] { MockBankStore.shared.beneficiaries }

    @MainActor
    static func transactions(accountId: String) -> [Transaction] {
        MockBankStore.shared.transactions(accountId: accountId)
    }
}
