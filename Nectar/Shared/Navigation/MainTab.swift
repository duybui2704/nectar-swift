import Foundation

/// 5 tab chính trong `MainShellView`. Mỗi tab giữ `NavigationStack` riêng.
enum MainTab: Int, Hashable, CaseIterable, Identifiable {
    case shop = 0
    case explore = 1
    case cart = 2
    case favourite = 3
    case account = 4

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .shop: return "Home"
        case .explore: return "Explore"
        case .cart: return "Cart"
        case .favourite: return "Favourite"
        case .account: return "Account"
        }
    }
}
