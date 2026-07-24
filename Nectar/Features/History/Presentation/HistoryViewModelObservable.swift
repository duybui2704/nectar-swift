import Foundation
import Observation

/// Modern @Observable ViewModel (iOS 17+) — compare with DashboardViewModel (ObservableObject).
@MainActor
@Observable
final class HistoryViewModelObservable {
    enum Status: Equatable {
        case idle, loading, success, failure(String)
    }

    enum Filter: String, CaseIterable, Identifiable {
        case all = "Tất cả"
        case inOut = "Thu chi"
        case transfer = "Chuyển tiền"
        var id: String { rawValue }
    }

    private(set) var status: Status = .idle
    private(set) var transactions: [Transaction] = []
    var selectedFilter: Filter = .all

    private let transactionRepo: TransactionRepository

    init(transactionRepo: TransactionRepository = MockTransactionRepository()) {
        self.transactionRepo = transactionRepo
    }

    var filteredTransactions: [Transaction] {
        switch selectedFilter {
        case .all: return transactions
        case .inOut: return transactions.filter { $0.category != .transfer }
        case .transfer: return transactions.filter { $0.category == .transfer }
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
