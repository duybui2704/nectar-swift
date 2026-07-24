import Foundation
import Combine

struct Offer: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let badge: String
    let expiryText: String
}

@MainActor
final class OffersViewModel: ObservableObject {
    enum Status: Equatable {
        case idle, loading, success, failure(String)
    }

    @Published private(set) var status: Status = .idle
    @Published private(set) var offers: [Offer] = []

    func load() async {
        status = .loading
        await MockBankAPI.delay(350)
        offers = [
            Offer(id: "o1", title: "Hoàn 50% Grab", subtitle: "Tối đa 30.000₫ / giao dịch", badge: "HOT", expiryText: "31/07/2026"),
            Offer(id: "o2", title: "Miễn phí chuyển tiền", subtitle: "3 lần/ngày nội bộ", badge: "MỚI", expiryText: "15/08/2026"),
            Offer(id: "o3", title: "Cashback điện", subtitle: "Thanh toán hóa đơn EVN", badge: "5%", expiryText: "30/09/2026"),
        ]
        status = .success
    }
}
