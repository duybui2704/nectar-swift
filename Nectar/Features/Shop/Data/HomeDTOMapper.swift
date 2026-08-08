import Foundation

/// Wire DTOs cho decode `event-box` envelope.
struct EventResponse: Codable {
    let result: EventResult
}

struct EventResult: Codable {
    let events: [EventBox]
}

/// Map JSON linh hoạt từ Printerval → domain models (schema API có thể lệch key).
enum HomeDTOMapper {

    // MARK: - Public

    static func banners(from data: Data) -> [HomeBanner] {
        guard let root = jsonObject(data) else { return [] }
        let rows = arrayPayload(from: root, preferredKeys: ["slides"])
        return rows.enumerated().compactMap { index, item in
            guard let dict = item as? [String: Any] else { return nil }
            let id = string(dict, keys: ["id", "banner_id", "uuid"]) ?? "banner-\(index)"
            let title = string(dict, keys: ["title", "name", "heading", "label"]) ?? ""
            let subtitle = string(dict, keys: ["subtitle", "sub_title", "description", "desc", "offer", "text"]) ?? ""
            let image = url(dict, keys: ["image", "image_url", "imageUrl", "banner", "banner_url", "url", "thumbnail"])
            if title.isEmpty && image == nil { return nil }
            return HomeBanner(
                id: id,
                title: title.isEmpty ? "Offer" : title,
                subtitle: subtitle,
                imageURL: image
            )
        }
    }

    /// Decode `category/tree` → **root nodes only** (không parse `children` sâu).
    static func categoryTree(from data: Data) -> [CategoryTree] {
        guard let root = jsonObject(data) else { return [] }
        let rows = arrayPayload(from: root, preferredKeys: ["result", "categories", "items", "data", "list"])
        return rows.enumerated().compactMap { index, item in
            guard let dict = item as? [String: Any] else { return nil }
            let id = number(dict, keys: ["id", "category_id"]).map { Int($0) }
                ?? Int(string(dict, keys: ["id", "category_id", "slug"]) ?? "")
                ?? index
            let name = string(dict, keys: ["name", "title", "label"]) ?? ""
            guard !name.isEmpty else { return nil }

            let typeRaw = string(dict, keys: ["type"]) ?? TypeEnum.product.rawValue
            let type = TypeEnum(rawValue: typeRaw) ?? .product

            return CategoryTree(
                id: id,
                name: name,
                type: type,
                parentID: number(dict, keys: ["parent_id"]).map { Int($0) },
                imageURL: string(dict, keys: ["image_url", "image", "icon", "thumbnail"]),
                slug: string(dict, keys: ["slug"]) ?? "",
                lft: number(dict, keys: ["lft"]).map { Int($0) } ?? 0,
                rgt: number(dict, keys: ["rgt"]).map { Int($0) } ?? 0,
                fullURL: string(dict, keys: ["full_url"]) ?? "",
                children: [] // Home chỉ cần root
            )
        }
    }
    
    static func sellerSpotlight(from data: Data) -> [Sellers] {
        guard let root = jsonObject(data) else { return [] }
        let rows = arrayPayload(from: root, preferredKeys: ["result", "sellers", "items", "data", "list"])
        return rows.compactMap { item in
            guard let dict = item as? [String: Any] else { return nil }

            let id = number(dict, keys: ["id", "seller_id", "sellerId"]).map { Int($0) }
                ?? Int(string(dict, keys: ["id", "seller_id", "sellerId"]) ?? "")
            guard let id else { return nil }

            let name = string(dict, keys: ["name", "title", "shop_name", "shopName"]) ?? ""
            guard !name.isEmpty else { return nil }

            return Sellers(
                id: id,
                name: name,
                slug: string(dict, keys: ["slug"]) ?? "",
                email: string(dict, keys: ["email"]),
                imageAvatar: string(dict, keys: ["imageAvatar", "image_avatar", "avatar", "image"]) ?? "",
                imageBackground: string(dict, keys: ["imageBackground", "image_background", "background", "cover"]) ?? "",
                status: string(dict, keys: ["status"]) ?? "",
                role: string(dict, keys: ["role"]) ?? "",
                type: string(dict, keys: ["type"]) ?? "",
                createdAt: string(dict, keys: ["createdAt", "created_at"]) ?? "",
                description: string(dict, keys: ["description", "desc"])
            )
        }
    }

    static func products(from data: Data) -> [ShopProduct] {
        guard let root = jsonObject(data) else { return [] }
        let rows = arrayPayload(from: root, preferredKeys: ["products", "items", "data", "list", "result"])
        return rows.enumerated().compactMap { index, item in
            product(from: item, fallbackIndex: index)
        }
    }

    static func eventBox(from data: Data) -> [EventBox] {
        do {
            let response = try JSONDecoder().decode(EventResponse.self, from: data)
            return response.result.events
        } catch {
            #if DEBUG
            print("Decode error eventBox:", error)
            #endif
            return []
        }
    }

    /// Decode `get-active-event` → danh sách banner (object hoặc mảng trong `result`).
    static func activeEvents(from data: Data) -> [ActiveEvent] {
        guard let root = jsonObject(data) else {
            #if DEBUG
            print("🎯 activeEvents: invalid JSON")
            #endif
            return []
        }

        // result == null
        if let dict = root as? [String: Any], dict["result"] is NSNull {
            #if DEBUG
            print("🎯 activeEvents: result is null")
            #endif
            return []
        }

        let rows: [Any]
        if let dict = root as? [String: Any] {
            let result = dict["result"] ?? dict["data"] ?? dict
            if let arr = result as? [Any] {
                rows = arr
            } else if let one = result as? [String: Any] {
                if let nested = one["events"] as? [Any]
                    ?? one["active_events"] as? [Any]
                    ?? one["active_event"] as? [Any]
                    ?? one["items"] as? [Any]
                    ?? one["list"] as? [Any] {
                    rows = nested
                } else if let nestedObj = one["event"] as? [String: Any]
                    ?? one["active_event"] as? [String: Any] {
                    rows = [nestedObj]
                } else {
                    rows = [one]
                }
            } else {
                rows = []
            }
        } else if let arr = root as? [Any] {
            rows = arr
        } else {
            rows = []
        }

        let mapped = rows.enumerated().compactMap { index, item -> ActiveEvent? in
            guard let dict = item as? [String: Any] else { return nil }
            let name = string(dict, keys: [
                "name", "title", "label", "heading", "event_name", "eventName",
            ]) ?? ""
            let image = url(dict, keys: [
                "image_url", "banner_url", "bannerUrl", "banner_season_url", "bannerSeasonUrl",
                "imageUrl", "image", "banner", "cover",
                "thumbnail", "thumb", "popup_image_url", "icon_url",
            ])
            guard !name.isEmpty || image != nil else { return nil }
            let id = string(dict, keys: ["id", "event_id", "eventId", "uuid", "slug"]) ?? "active-\(index)"
            let desc = string(dict, keys: [
                "description", "desc", "subtitle", "sub_title", "day", "content",
            ]) ?? ""
            return ActiveEvent(
                id: id,
                name: name.isEmpty ? "Event" : name,
                description: desc,
                bannerURL: image
            )
        }

        #if DEBUG
        if mapped.isEmpty {
            let keys: Any
            if let d = root as? [String: Any] {
                keys = d.keys.sorted()
            } else {
                keys = type(of: root)
            }
            print("🎯 activeEvents: mapped 0 — root keys/type:", keys)
        }
        #endif
        return mapped
    }

    /// Parse `EventBox.pageData` (JSON string) → products tab đầu.
    static func eventPageProducts(from pageDataJSON: String) -> [ShopProduct] {
        guard let tabs = eventPageTabsObject(from: pageDataJSON),
              let first = tabs.first else { return [] }

        let pageData = dictionaryValue(first, keys: ["page_data", "pageData"]) ?? [:]

        let rows = pageData["products"] as? [Any]
            ?? pageData["items"] as? [Any]
            ?? first["products"] as? [Any]
            ?? []

        return rows.enumerated().compactMap { index, item in
            product(from: item, fallbackIndex: index)
        }
    }

    static func eventPageTabTitle(from pageDataJSON: String) -> String? {
        guard let tabs = eventPageTabsObject(from: pageDataJSON),
              let first = tabs.first else { return nil }
        return string(first, keys: ["title", "name", "label"])
    }

    /// Decode `product-video/find` → reels.
    static func productReels(from data: Data) -> [ProductReel] {
        guard let root = jsonObject(data) else { return [] }
        let rows = arrayPayload(from: root, preferredKeys: ["result", "videos", "items", "data", "list"])
        return rows.compactMap { item in
            guard let dict = item as? [String: Any] else { return nil }

            let idValue = dict["id"] as? Int
                ?? (dict["id"] as? NSNumber)?.intValue
                ?? Int(string(dict, keys: ["id"]) ?? "")
            guard let id = idValue else { return nil }

            let product = dict["product"] as? [String: Any] ?? [:]
            let productId = (product["id"] as? Int)
                ?? (product["id"] as? NSNumber)?.intValue
                ?? (dict["product_id"] as? Int)
                ?? (dict["product_id"] as? NSNumber)?.intValue
                ?? 0

            let name = string(product, keys: ["name", "title"]) ?? ""
            let displayPrice = string(product, keys: ["display_price", "displayPrice", "price"]) ?? ""

            return ProductReel(
                id: id,
                thumbnailURL: url(dict, keys: ["image_url", "imageUrl", "thumbnail", "thumb"]),
                videoURL: url(dict, keys: ["src", "video_url", "videoUrl", "url"]),
                productId: productId,
                productName: name.isEmpty ? "Product" : name,
                displayPrice: displayPrice,
                productImageURL: url(product, keys: ["image_url", "imageUrl", "image"])
            )
        }
    }

    // MARK: - Private

    private static func eventPageTabsObject(from pageDataJSON: String) -> [[String: Any]]? {
        let trimmed = pageDataJSON.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let data = trimmed.data(using: .utf8),
              let root = jsonObject(data) else { return nil }

        if let dict = root as? [String: Any] {
            if let tabs = dict["tabs"] as? [[String: Any]] { return tabs }
            if let result = dict["result"] as? [String: Any],
               let tabs = result["tabs"] as? [[String: Any]] {
                return tabs
            }
        }
        if let tabs = root as? [[String: Any]] { return tabs }
        return nil
    }

    private static func dictionaryValue(_ dict: [String: Any], keys: [String]) -> [String: Any]? {
        for key in keys {
            if let nested = dict[key] as? [String: Any] { return nested }
            if let s = dict[key] as? String,
               let data = s.data(using: .utf8),
               let nested = jsonObject(data) as? [String: Any] {
                return nested
            }
        }
        return nil
    }

    private static func product(from item: Any, fallbackIndex: Int) -> ShopProduct? {
        guard let dict = item as? [String: Any] else { return nil }

        let name = string(dict, keys: ["name", "title", "product_name", "productName", "label"]) ?? ""
        guard !name.isEmpty else { return nil }

        let unit = string(dict, keys: [
            "unit", "unit_label", "quantity", "qty", "weight",
            "short_description", "shortDescription", "attribute", "variant", "desc",
        ]) ?? ""

        let isFav = dict["isFavourite"] as? Bool ?? false

        let price = number(dict, keys: [
            "price", "sale_price", "salePrice", "final_price", "finalPrice",
            "display_price", "amount", "min_price",
        ]) ?? 0

        var image = url(dict, keys: [
            "image", "image_url", "imageUrl", "thumbnail", "thumb",
            "photo", "cover", "main_image",
        ])
        if image == nil, let images = dict["images"] as? [Any], let first = images.first {
            if let s = first as? String {
                image = URL(string: s)
            } else if let d = first as? [String: Any] {
                image = url(d, keys: ["url", "src", "image", "path"])
            }
        }

        // Ưu tiên id số (product API); tránh sku/uuid làm path `product/{id}`.
        let id = string(dict, keys: ["product_id", "productId", "id", "design_id", "designId"])
            ?? string(dict, keys: ["sku", "uuid"])
            ?? "product-\(fallbackIndex)"

        return ShopProduct(
            id: id,
            name: name,
            unitLabel: unit.isEmpty ? "1 unit" : unit,
            price: price,
            imageURL: image,
            isFavorite: isFav
        )
    }

    private static func jsonObject(_ data: Data) -> Any? {
        try? JSONSerialization.jsonObject(with: data)
    }

    private static func arrayPayload(from root: Any, preferredKeys: [String]) -> [Any] {
        if let arr = root as? [Any] { return arr }

        guard let dict = root as? [String: Any] else { return [] }

        let result = dict["result"] ?? dict["data"] ?? dict

        if let arr = result as? [Any] { return arr }

        if let resultDict = result as? [String: Any] {
            for key in preferredKeys {
                if let arr = resultDict[key] as? [Any] { return arr }
            }
            for nestedKey in ["data", "items"] {
                if let nested = resultDict[nestedKey] as? [String: Any] {
                    for key in preferredKeys {
                        if let arr = nested[key] as? [Any] { return arr }
                    }
                }
            }
        }

        for key in preferredKeys {
            if let arr = dict[key] as? [Any] { return arr }
        }

        return []
    }

    private static func string(_ dict: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let s = dict[key] as? String, !s.isEmpty { return s }
            if let n = dict[key] as? NSNumber { return n.stringValue }
        }
        return nil
    }

    private static func number(_ dict: [String: Any], keys: [String]) -> Double? {
        for key in keys {
            if let d = dict[key] as? Double { return d }
            if let i = dict[key] as? Int { return Double(i) }
            if let n = dict[key] as? NSNumber { return n.doubleValue }
            if let s = dict[key] as? String {
                let cleaned = s.replacingOccurrences(of: "[^0-9.]", with: "", options: .regularExpression)
                if let d = Double(cleaned) { return d }
            }
        }
        return nil
    }

    private static func url(_ dict: [String: Any], keys: [String]) -> URL? {
        guard let raw = string(dict, keys: keys) else { return nil }
        if raw.hasPrefix("//") {
            return URL(string: "https:" + raw)
        }
        if raw.hasPrefix("/") {
            return URL(string: "https://printerval.com" + raw)
        }
        return URL(string: raw)
    }
}
