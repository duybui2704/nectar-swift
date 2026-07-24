import Foundation

struct BankAccount: Identifiable, Equatable, Hashable {
    enum AccountType: String {
        case checking
        case savings
        case foreign
    }

    let id: String
    let name: String
    let numberMasked: String
    let type: AccountType
    let currency: String
    let balance: Decimal
    let availableBalance: Decimal
}

struct Transaction: Identifiable, Equatable, Hashable {
    enum Category: String {
        case food, income, transfer, bills, cash, other
    }

    enum Status: String {
        case pending, posted, failed
    }

    let id: String
    let accountId: String
    let title: String
    let subtitle: String
    let amount: Decimal
    let currency: String
    let date: Date
    let category: Category
    let status: Status

    var isCredit: Bool { amount > 0 }
}

struct BankCard: Identifiable, Equatable, Hashable {
    let id: String
    let brand: String
    let last4: String
    let holderName: String
    let expiry: String
    var isFrozen: Bool
    let limit: Decimal
}

struct Beneficiary: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let bankName: String
    let accountMasked: String
}

struct TransferRequest: Equatable {
    let fromAccountId: String
    let beneficiaryId: String?
    let newRecipientName: String?
    let newRecipientBank: String?
    let newRecipientAccount: String?
    let amount: Decimal
    let note: String
    let currency: String
}

struct TransferResult: Equatable {
    let referenceId: String
    let completedAt: Date
}
