import Foundation
import Combine

@MainActor
final class CardsViewModel: ObservableObject {
    enum Status: Equatable {
        case idle, loading, success, failure(String)
    }

    @Published private(set) var status: Status = .idle
    @Published private(set) var cards: [BankCard] = []

    private let repo: CardRepository

    init(repo: CardRepository = MockCardRepository()) {
        self.repo = repo
    }

    func load() async {
        status = .loading
        do {
            cards = try await repo.fetchCards()
            status = .success
        } catch {
            status = .failure(error.localizedDescription)
        }
    }

    func toggleFreeze(_ card: BankCard) async {
        do {
            let updated = try await repo.setFrozen(cardId: card.id, frozen: !card.isFrozen)
            if let index = cards.firstIndex(where: { $0.id == card.id }) {
                cards[index] = updated
            }
        } catch {
            status = .failure(error.localizedDescription)
        }
    }
}
