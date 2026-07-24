import Foundation

/// Mutable in-memory store so transfers update balances & history (demo loop).
@MainActor
final class MockNectarStore {
    static let shared = MockNectarStore()

    private(set) var accounts: [AppAccount]
    private(set) var cards: [AppCard]
    private(set) var beneficiaries: [Beneficiary]
    private var transactionsByAccount: [String: [Transaction]]

    private init() {
        accounts = [
            AppAccount(
                id: "acc-checking",
                name: "Ví thanh toán",
                numberMasked: "**** 4821",
                type: .checking,
                currency: "VND",
                balance: 48_250_000,
                availableBalance: 48_250_000
            ),
            AppAccount(
                id: "acc-saving",
                name: "Tiết kiệm",
                numberMasked: "**** 0193",
                type: .savings,
                currency: "VND",
                balance: 120_000_000,
                availableBalance: 120_000_000
            ),
            AppAccount(
                id: "acc-usd",
                name: "Ngoại tệ USD",
                numberMasked: "**** 7710",
                type: .foreign,
                currency: "USD",
                balance: 1_250,
                availableBalance: 1_250
            ),
        ]
        cards = [
            AppCard(
                id: "card-visa",
                brand: "Visa",
                last4: "4242",
                holderName: "NGUYEN VAN A",
                expiry: "09/28",
                isFrozen: false,
                limit: 50_000_000
            ),
            AppCard(
                id: "card-debit",
                brand: "Napas Debit",
                last4: "1188",
                holderName: "NGUYEN VAN A",
                expiry: "01/29",
                isFrozen: false,
                limit: 20_000_000
            ),
        ]
        beneficiaries = [
            Beneficiary(id: "ben-1", name: "Trần Thị B", bankName: "Vietcombank", accountMasked: "**** 3344"),
            Beneficiary(id: "ben-2", name: "Lê Văn C", bankName: "Techcombank", accountMasked: "**** 8890"),
            Beneficiary(id: "ben-3", name: "Mẹ", bankName: "MB Bank", accountMasked: "**** 1122"),
        ]
        transactionsByAccount = Dictionary(
            uniqueKeysWithValues: accounts.map { ($0.id, Self.seedTransactions(accountId: $0.id)) }
        )
    }

    func account(id: String) -> AppAccount? {
        accounts.first { $0.id == id }
    }

    func transactions(accountId: String) -> [Transaction] {
        transactionsByAccount[accountId] ?? []
    }

    func allTransactionsSorted() -> [Transaction] {
        transactionsByAccount.values
            .flatMap { $0 }
            .sorted { $0.date > $1.date }
    }

    @discardableResult
    func setCardFrozen(cardId: String, frozen: Bool) throws -> AppCard {
        guard let index = cards.firstIndex(where: { $0.id == cardId }) else {
            throw AppError.notFound
        }
        cards[index].isFrozen = frozen
        return cards[index]
    }

    func addBeneficiary(_ beneficiary: Beneficiary) {
        if !beneficiaries.contains(where: { $0.id == beneficiary.id }) {
            beneficiaries.insert(beneficiary, at: 0)
        }
    }

    func applyTransfer(_ request: TransferRequest, beneficiary: Beneficiary) throws -> TransferResult {
        guard request.amount >= TransferConstants.minimumAmountVND else {
            throw AppError.validation("Số tiền tối thiểu \(MoneyFormatter.format(TransferConstants.minimumAmountVND)).")
        }
        guard request.amount <= TransferConstants.maximumAmountVND else {
            throw AppError.validation("Vượt hạn mức chuyển khoản demo.")
        }
        guard let index = accounts.firstIndex(where: { $0.id == request.fromAccountId }) else {
            throw AppError.notFound
        }
        let source = accounts[index]
        guard source.availableBalance >= request.amount else {
            throw AppError.validation("Số dư không đủ.")
        }

        let newBalance = source.balance - request.amount
        accounts[index] = AppAccount(
            id: source.id,
            name: source.name,
            numberMasked: source.numberMasked,
            type: source.type,
            currency: source.currency,
            balance: newBalance,
            availableBalance: newBalance
        )

        let referenceId = "FT\(Int(Date().timeIntervalSince1970))"
        let note = request.note.isEmpty ? "Chuyển tiền" : request.note
        let tx = Transaction(
            id: "tx-\(referenceId)",
            accountId: source.id,
            title: "Chuyển đến \(beneficiary.name)",
            subtitle: "\(beneficiary.bankName) · \(note)",
            amount: -request.amount,
            currency: request.currency,
            date: Date(),
            category: .transfer,
            status: .posted
        )
        var list = transactionsByAccount[source.id] ?? []
        list.insert(tx, at: 0)
        transactionsByAccount[source.id] = list

        addBeneficiary(beneficiary)

        return TransferResult(referenceId: referenceId, completedAt: Date())
    }

    private static func seedTransactions(accountId: String) -> [Transaction] {
        [
            Transaction(
                id: "tx-1-\(accountId)",
                accountId: accountId,
                title: "Grab Food",
                subtitle: "Thanh toán QR",
                amount: -185_000,
                currency: "VND",
                date: Date().addingTimeInterval(-3600 * 5),
                category: .food,
                status: .posted
            ),
            Transaction(
                id: "tx-2-\(accountId)",
                accountId: accountId,
                title: "Lương tháng 7",
                subtitle: "Công ty ABC",
                amount: 25_000_000,
                currency: "VND",
                date: Date().addingTimeInterval(-3600 * 28),
                category: .income,
                status: .posted
            ),
            Transaction(
                id: "tx-3-\(accountId)",
                accountId: accountId,
                title: "Chuyển đến Trần B",
                subtitle: "Nội bộ",
                amount: -2_000_000,
                currency: "VND",
                date: Date().addingTimeInterval(-3600 * 50),
                category: .transfer,
                status: .posted
            ),
            Transaction(
                id: "tx-4-\(accountId)",
                accountId: accountId,
                title: "Điện lực",
                subtitle: "Hóa đơn tự động",
                amount: -650_000,
                currency: "VND",
                date: Date().addingTimeInterval(-3600 * 72),
                category: .bills,
                status: .posted
            ),
            Transaction(
                id: "tx-5-\(accountId)",
                accountId: accountId,
                title: "ATM rút tiền",
                subtitle: "Chi nhánh Q1",
                amount: -1_000_000,
                currency: "VND",
                date: Date().addingTimeInterval(-3600 * 96),
                category: .cash,
                status: .posted
            ),
        ]
    }
}
