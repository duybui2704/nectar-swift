import Foundation

/// Banner home (API `home/get-banners`).
struct HomeBanner: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let imageURL: URL?
}

/// Category tree node — API `category/tree` / `home/get-categories` (`result[]`).
/// Nested `children` đệ quy theo nested set (`lft`/`rgt`).
struct CategoryTree: Identifiable, Hashable, Decodable, Sendable {
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

    enum CodingKeys: String, CodingKey {
        case id, name, type, slug, children, lft, rgt
        case parentId = "parent_id"
        case imageURL = "image_url"
        case fullURL = "full_url"
    }

    init(
        id: Int,
        name: String,
        type: String,
        parentId: Int?,
        imageURL: URL?,
        slug: String,
        lft: Int?,
        rgt: Int?,
        fullURL: String?,
        children: [CategoryTree]
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.parentId = parentId
        self.imageURL = imageURL
        self.slug = slug
        self.lft = lft
        self.rgt = rgt
        self.fullURL = fullURL
        self.children = children
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try Self.decodeFlexibleInt(c, forKey: .id) ?? 0
        name = try c.decodeIfPresent(String.self, forKey: .name) ?? ""
        type = try c.decodeIfPresent(String.self, forKey: .type) ?? "PRODUCT"
        parentId = try Self.decodeFlexibleInt(c, forKey: .parentId)
        slug = try c.decodeIfPresent(String.self, forKey: .slug) ?? ""
        lft = try Self.decodeFlexibleInt(c, forKey: .lft)
        rgt = try Self.decodeFlexibleInt(c, forKey: .rgt)
        fullURL = try c.decodeIfPresent(String.self, forKey: .fullURL)
        children = try c.decodeIfPresent([CategoryTree].self, forKey: .children) ?? []
        imageURL = Self.decodeURL(try c.decodeIfPresent(String.self, forKey: .imageURL))
    }

    var hasChildren: Bool { !children.isEmpty }

    /// Bản shallow cho Home rail — giữ metadata root, bỏ cây con (tiết kiệm RAM).
    var asRootOnly: CategoryTree {
        CategoryTree(
            id: id,
            name: name,
            type: type,
            parentId: parentId,
            imageURL: imageURL,
            slug: slug,
            lft: lft,
            rgt: rgt,
            fullURL: fullURL,
            children: []
        )
    }

    private static func decodeURL(_ raw: String?) -> URL? {
        guard let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        if raw.hasPrefix("//") { return URL(string: "https:" + raw) }
        return URL(string: raw)
    }

    /// API đôi khi trả `id` dạng Int hoặc String.
    private static func decodeFlexibleInt(
        _ c: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) throws -> Int? {
        if let v = try? c.decodeIfPresent(Int.self, forKey: key) { return v }
        if let s = try? c.decodeIfPresent(String.self, forKey: key), let v = Int(s) { return v }
        return nil
    }
}

/// Envelope `{ status, result: [CategoryTree] }`.
struct CategoryTreePayload: Decodable, Sendable {
    let status: String?
    let result: [CategoryTree]

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        status = try c.decodeIfPresent(String.self, forKey: .status)
        if let arr = try? c.decode([CategoryTree].self, forKey: .result) {
            result = arr
        } else {
            result = []
        }
    }

    private enum CodingKeys: String, CodingKey {
        case status, result
    }
}

/// Product card trên Home (recommendation / big-deals / …).
struct ShopProduct: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let name: String
    /// VD: "7pcs, Priceg", "1kg, Priceg"
    let unitLabel: String
    let price: Double
    let imageURL: URL?

    func formattedPrice(symbol: String = "$") -> String {
        if price == floor(price) {
            return "\(symbol)\(Int(price))"
        }
        return String(format: "%@%.2f", symbol, price)
    }
}

struct EventResponse: Codable {
    let result: EventResult
}

struct EventResult: Codable {
    let events: [EventBox]
}

struct EventBox: Codable {
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

    /// Title tab đầu trong `page_data`.
    var pageTabTitle: String {
        HomeDTOMapper.eventPageTabTitle(from: pageData) ?? name
    }

    /// Products tab đầu — map linh hoạt (không dùng Codable `ShopProduct`).
    var pageProducts: [ShopProduct] {
        HomeDTOMapper.eventPageProducts(from: pageData)
    }
}
