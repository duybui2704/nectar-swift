import Foundation

final class MockAccountRepository: AccountRepository {
    func fetchAccounts() async throws -> [AppAccount] {
        await MockNectarAPI.delay()
        return await MockNectarStore.shared.accounts
    }

    func fetchAccount(id: String) async throws -> AppAccount {
        await MockNectarAPI.delay(300)
        guard let account = await MockNectarStore.shared.account(id: id) else {
            throw AppError.notFound
        }
        return account
    }
}

final class MockTransactionRepository: TransactionRepository {
    func fetchRecent(accountId: String, limit: Int) async throws -> [Transaction] {
        await MockNectarAPI.delay()
        let txs = await MockNectarStore.shared.transactions(accountId: accountId)
        return Array(txs.prefix(limit))
    }

    func fetchAll(accountId: String) async throws -> [Transaction] {
        await MockNectarAPI.delay()
        return await MockNectarStore.shared.transactions(accountId: accountId)
    }

    func fetchGlobalRecent(limit: Int) async throws -> [Transaction] {
        await MockNectarAPI.delay()
        let txs = await MockNectarStore.shared.allTransactionsSorted()
        return Array(txs.prefix(limit))
    }
}

final class MockTransferRepository: TransferRepository {
    func fetchBeneficiaries() async throws -> [Beneficiary] {
        await MockNectarAPI.delay(250)
        return await MockNectarStore.shared.beneficiaries
    }

    func submit(_ request: TransferRequest) async throws -> TransferResult {
        await MockNectarAPI.delay(800)
        let beneficiary = try await resolveBeneficiary(for: request)
        return try await MockNectarStore.shared.applyTransfer(request, beneficiary: beneficiary)
    }

    private func resolveBeneficiary(for request: TransferRequest) async throws -> Beneficiary {
        if let id = request.beneficiaryId,
           let existing = await MockNectarStore.shared.beneficiaries.first(where: { $0.id == id }) {
            return existing
        }

        guard let name = request.newRecipientName?.trimmingCharacters(in: .whitespacesAndNewlines),
              !name.isEmpty,
              let bank = request.newRecipientBank?.trimmingCharacters(in: .whitespacesAndNewlines),
              !bank.isEmpty,
              let account = request.newRecipientAccount?.trimmingCharacters(in: .whitespacesAndNewlines),
              account.count >= 6
        else {
            throw AppError.validation("Thông tin người nhận không hợp lệ.")
        }

        let masked = "**** \(String(account.suffix(4)))"
        return Beneficiary(
            id: "ben-\(account)",
            name: name,
            bankName: bank,
            accountMasked: masked
        )
    }
}

final class MockCardRepository: CardRepository {
    func fetchCards() async throws -> [AppCard] {
        await MockNectarAPI.delay()
        return await MockNectarStore.shared.cards
    }

    func setFrozen(cardId: String, frozen: Bool) async throws -> AppCard {
        await MockNectarAPI.delay(400)
        return try await MockNectarStore.shared.setCardFrozen(cardId: cardId, frozen: frozen)
    }
}
