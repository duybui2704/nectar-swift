import Foundation

/// Remote account fetch via JSONPlaceholder — proves Repository swap without changing View.
struct RemoteUserDTO: Decodable {
    let id: Int
    let name: String
}

final class APIAccountRepository: AccountRepository {
    private let client: APIClient

    init(client: APIClient = .shared) {
        self.client = client
    }

    func fetchAccounts() async throws -> [BankAccount] {
        let user = try await client.get("/users/1", as: RemoteUserDTO.self, authenticated: false)
        await MockBankAPI.delay(200)
        // Map remote response into local domain; balance still from mock store for demo consistency
        let mockAccounts = await MockBankStore.shared.accounts
        guard let primary = mockAccounts.first else { return [] }
        return [
            BankAccount(
                id: primary.id,
                name: "Ví \(user.name)",
                numberMasked: primary.numberMasked,
                type: primary.type,
                currency: primary.currency,
                balance: primary.balance,
                availableBalance: primary.availableBalance
            ),
        ] + Array(mockAccounts.dropFirst())
    }

    func fetchAccount(id: String) async throws -> BankAccount {
        _ = try await client.get("/users/1", as: RemoteUserDTO.self, authenticated: false)
        guard let account = await MockBankStore.shared.account(id: id) else {
            throw AppError.notFound
        }
        return account
    }
}
