import Foundation

protocol AccountRepository {
    func fetchAccounts() async throws -> [BankAccount]
    func fetchAccount(id: String) async throws -> BankAccount
}

protocol TransactionRepository {
    func fetchRecent(accountId: String, limit: Int) async throws -> [Transaction]
    func fetchAll(accountId: String) async throws -> [Transaction]
    func fetchGlobalRecent(limit: Int) async throws -> [Transaction]
}

protocol TransferRepository {
    func fetchBeneficiaries() async throws -> [Beneficiary]
    func submit(_ request: TransferRequest) async throws -> TransferResult
}

protocol CardRepository {
    func fetchCards() async throws -> [BankCard]
    func setFrozen(cardId: String, frozen: Bool) async throws -> BankCard
}
