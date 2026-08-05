import Foundation

/// Màn **push** trong `NavigationStack` — typed, Hashable, dùng chung mọi tab.
/// Thêm case mới ở đây + map UI trong `AppDestinationView`.
enum AppDestination: Hashable {
    case productDetail(id: String)
    case category(id: Int, name: String)
    case search(query: String)
    case orders
    case deliveryAddress
    case changePassword
    case pinSettings
}

/// Modal `.sheet`.
enum AppSheet: Identifiable, Hashable {
    case filters

    var id: Self { self }
}

/// Modal `.fullScreenCover`.
enum AppFullScreen: Identifiable, Hashable {
    case productReel(initialID: Int)

    var id: Self { self }
}
