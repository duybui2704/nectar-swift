import Foundation

/// Banner home (API `home/get-banners`).
struct HomeBanner: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let imageURL: URL?
}

/// Category tree node — API `category/tree` (Home chỉ dùng root).
struct CategoryTree: Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let type: String
    let parentId: Int?
    let imageURL: URL?
    let slug: String
    let lft: Int?
    let rgt: Int?
    let fullURL: String?
    let children: [CategoryTree]

    var hasChildren: Bool { !children.isEmpty }
}

/// Product card trên Home (recommendation / big-deals / …).
struct ShopProduct: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let name: String
    /// VD: "7pcs, Priceg", "1kg, Priceg"
    let unitLabel: String
    let price: Double
    let imageURL: URL?

    func formattedPrice(symbol: String = "$") -> String? {
        guard price > 0 else { return nil }

        if price == floor(price) {
            return "\(symbol)\(Int(price))"
        }

        return String(format: "%@%.2f", symbol, price)
    }
}

/// Event promo — API `event-box`.
struct EventBox: Codable, Hashable, Sendable {
    let id: Int
    let name: String
    let day: String
    let countryId: String?
    let categoryId: String?
    let description: String
    let createdAt: String
    let updatedAt: String
    let imageUrl: String
    let bannerSeasonUrl: String?
    let popupImageUrl: String?
    let bannerUrl: String
    let iconUrl: String?
    let eventBtnColor: String?
    let status: String
    let metaData: String
    let endAt: String
    let slug: String
    let isShowPopup: String?
    /// JSON string: `{ "tabs": [ { "title", "page_data": { "products": [...] } } ] }`
    let pageData: String
    let type: String
    let isAdvertising: Int

    enum CodingKeys: String, CodingKey {
        case id, name, day, description, status, slug, type
        case countryId = "country_id"
        case categoryId = "category_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case imageUrl = "image_url"
        case bannerSeasonUrl = "banner_season_url"
        case popupImageUrl = "popup_image_url"
        case bannerUrl = "banner_url"
        case iconUrl = "icon_url"
        case eventBtnColor = "event_btn_color"
        case metaData = "meta_data"
        case endAt = "end_at"
        case isShowPopup = "is_show_popup"
        case pageData = "page_data"
        case isAdvertising = "is_advertising"
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
