import Foundation

/// Parse `nectar://…` → route nội bộ. `AppRouter` chịu trách nhiệm apply.
///
/// Ví dụ:
/// - `nectar://cart`
/// - `nectar://explore`
/// - `nectar://product/42`
/// - `nectar://category/7?name=Fruits`
/// - `nectar://account/orders`
/// - `nectar://search?q=milk`
enum DeepLinkRouter {
    enum Route: Equatable {
        case tab(MainTab)
        case destination(tab: MainTab, AppDestination, replace: Bool)
    }

    static func parse(_ url: URL) -> Route? {
        guard url.scheme == "nectar" else { return nil }

        let host = (url.host ?? "").lowercased()
        let parts = url.pathComponents.filter { $0 != "/" }
        let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []

        func queryValue(_ name: String) -> String? {
            query.first(where: { $0.name == name })?.value
        }

        switch host {
        case "shop", "home":
            return .tab(.shop)

        case "explore":
            return .tab(.explore)

        case "cart":
            return .tab(.cart)

        case "favourite", "favorite":
            return .tab(.favourite)

        case "account", "profile":
            if parts.first == "orders" {
                return .destination(tab: .account, .orders, replace: true)
            }
            if parts.first == "address" {
                return .destination(tab: .account, .deliveryAddress, replace: true)
            }
            return .tab(.account)

        case "product":
            guard let raw = parts.first, !raw.isEmpty else { return nil }
            return .destination(tab: .shop, .productDetail(id: raw), replace: true)

        case "category":
            guard let raw = parts.first, let id = Int(raw) else { return nil }
            let name = queryValue("name") ?? "Category"
            return .destination(tab: .explore, .category(id: id, name: name), replace: true)

        case "search":
            let q = queryValue("q") ?? queryValue("query") ?? ""
            return .destination(tab: .explore, .search(query: q), replace: true)

        case "orders":
            return .destination(tab: .account, .orders, replace: true)

        default:
            return nil
        }
    }
}
