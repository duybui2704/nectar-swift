import Foundation

/// Event promo — API `event-box` (`events` / `upcoming_events`).
/// Dùng chung Shop (Home) + Explore.
struct EventBox: Identifiable, Codable, Hashable, Sendable {
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

    var bannerURL: URL? {
        Self.makeURL(bannerUrl.isEmpty ? imageUrl : bannerUrl)
    }

    private static func makeURL(_ raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed.hasPrefix("//") { return URL(string: "https:" + trimmed) }
        if trimmed.hasPrefix("/") { return URL(string: "https://printerval.com" + trimmed) }
        return URL(string: trimmed)
    }
}
