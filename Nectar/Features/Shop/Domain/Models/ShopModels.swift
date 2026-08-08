import Foundation

/// Banner home (API `home/get-banners`).
struct HomeBanner: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let imageURL: URL?
}

/// Product card trên Home (recommendation / big-deals / …).
struct ShopProduct: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let name: String
    /// VD: "7pcs, Priceg", "1kg, Priceg"
    let unitLabel: String
    let price: Double
    let imageURL: URL?
    let isFavorite: Bool

    func formattedPrice(symbol: String = "$") -> String? {
        guard price > 0 else { return nil }

        if price == floor(price) {
            return "\(symbol)\(Int(price))"
        }

        return String(format: "%@%.2f", symbol, price)
    }
}

/// Product video / Reel — API `product-video/find`.
struct ProductReel: Identifiable, Hashable, Sendable {
    let id: Int
    let thumbnailURL: URL?
    let videoURL: URL?
    let productId: Int
    let productName: String
    let displayPrice: String
    let productImageURL: URL?
}

/// Seller spotlight — API `seller/spotlight`.
struct Sellers: Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let slug: String
    let email: String?
    let imageAvatar: String
    let imageBackground: String
    let status: String
    let role: String
    let type: String
    let createdAt: String
    let description: String?

    var avatarURL: URL? { Self.makeURL(imageAvatar) }
    var backgroundURL: URL? { Self.makeURL(imageBackground) }

    private static func makeURL(_ raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.hasPrefix("//") { return URL(string: "https:" + trimmed) }
        if trimmed.hasPrefix("/") { return URL(string: "https://printerval.com" + trimmed) }
        return URL(string: trimmed)
    }
}
