import Foundation
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    enum Status: Equatable {
        case idle, loading, success, failure(String)
    }

    @Published private(set) var status: Status = .idle
    @Published private(set) var accounts: [BankAccount] = []
    @Published private(set) var recentTransactions: [Transaction] = []
    @Published private(set) var totalBalanceVND: Decimal = 0

    private let accountRepo: AccountRepository
    private let transactionRepo: TransactionRepository

    init(
        accountRepo: AccountRepository = MockAccountRepository(),
        transactionRepo: TransactionRepository = MockTransactionRepository()
    ) {
        self.accountRepo = accountRepo
        self.transactionRepo = transactionRepo
    }

    func load() async {
        status = .loading
        do {
            async let accountsTask = accountRepo.fetchAccounts()
            async let txsTask = transactionRepo.fetchGlobalRecent(limit: 5)
            let loadedAccounts = try await accountsTask
            let txs = try await txsTask

            accounts = loadedAccounts
            recentTransactions = txs
            totalBalanceVND = loadedAccounts
                .filter { $0.currency == "VND" }
                .map(\.balance)
                .reduce(0, +)
            WidgetDataStore.updateBalance(totalBalanceVND)
            status = .success
        } catch {
            status = .failure(error.localizedDescription)
        }
    }
}
