import Foundation

protocol AccountRepository {
    func fetchAccounts() async throws -> [AppAccount]
    func fetchAccount(id: String) async throws -> AppAccount
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
    func fetchCards() async throws -> [AppCard]
    func setFrozen(cardId: String, frozen: Bool) async throws -> AppCard
}
