import Foundation
import Combine

@MainActor
final class AccountDetailViewModel: ObservableObject {
    enum Status: Equatable {
        case idle, loading, success, failure(String)
    }

    @Published private(set) var status: Status = .idle
    @Published private(set) var account: AppAccount?
    @Published private(set) var transactions: [Transaction] = []

    private let accountId: String
    private let accountRepo: AccountRepository
    private let transactionRepo: TransactionRepository

    init(
        accountId: String,
        accountRepo: AccountRepository = MockAccountRepository(),
        transactionRepo: TransactionRepository = MockTransactionRepository()
    ) {
        self.accountId = accountId
        self.accountRepo = accountRepo
        self.transactionRepo = transactionRepo
    }

    func load() async {
        status = .loading
        do {
            async let accountTask = accountRepo.fetchAccount(id: accountId)
            async let txsTask = transactionRepo.fetchAll(accountId: accountId)
            account = try await accountTask
            transactions = try await txsTask
            status = .success
        } catch {
            status = .failure(error.localizedDescription)
        }
    }
}
