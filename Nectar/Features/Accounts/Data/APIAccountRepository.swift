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

    func fetchAccounts() async throws -> [AppAccount] {
        let user = try await client.get("/users/1", as: RemoteUserDTO.self, authenticated: false)
        await MockNectarAPI.delay(200)
        // Map remote response into local domain; balance still from mock store for demo consistency
        let mockAccounts = await MockNectarStore.shared.accounts
        guard let primary = mockAccounts.first else { return [] }
        return [
            AppAccount(
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

    func fetchAccount(id: String) async throws -> AppAccount {
        _ = try await client.get("/users/1", as: RemoteUserDTO.self, authenticated: false)
        guard let account = await MockNectarStore.shared.account(id: id) else {
            throw AppError.notFound
        }
        return account
    }
}
