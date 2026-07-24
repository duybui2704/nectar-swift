import Foundation
import Combine

@MainActor
final class HistoryViewModel: ObservableObject {
    enum Status: Equatable {
        case idle, loading, success, failure(String)
    }

    @Published private(set) var status: Status = .idle
    @Published private(set) var transactions: [Transaction] = []
    @Published var selectedFilter: Filter = .all

    enum Filter: String, CaseIterable, Identifiable {
        case all = "Tất cả"
        case inOut = "Thu chi"
        case transfer = "Chuyển tiền"

        var id: String { rawValue }
    }

    private let transactionRepo: TransactionRepository

    init(transactionRepo: TransactionRepository = MockTransactionRepository()) {
        self.transactionRepo = transactionRepo
    }

    var filteredTransactions: [Transaction] {
        switch selectedFilter {
        case .all:
            return transactions
        case .inOut:
            return transactions.filter { $0.category != .transfer }
        case .transfer:
            return transactions.filter { $0.category == .transfer }
        }
    }

    func load() async {
        status = .loading
        do {
            transactions = try await transactionRepo.fetchGlobalRecent(limit: 50)
            status = .success
        } catch {
            status = .failure(error.localizedDescription)
        }
    }
}
