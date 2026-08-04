import Foundation

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
            let id = number(dict, keys: ["id", "category_id"]) .map { Int($0) }
                ?? Int(string(dict, keys: ["id", "category_id", "slug"]) ?? "")
                ?? index
            let name = string(dict, keys: ["name", "title", "label"]) ?? ""
            guard !name.isEmpty else { return nil }
            return CategoryTree(
                id: id,
                name: name,
                type: string(dict, keys: ["type"]) ?? "PRODUCT",
                parentId: number(dict, keys: ["parent_id"]).map { Int($0) },
                imageURL: url(dict, keys: ["image_url", "image", "icon", "thumbnail"]),
                slug: string(dict, keys: ["slug"]) ?? "",
                lft: number(dict, keys: ["lft"]).map { Int($0) },
                rgt: number(dict, keys: ["rgt"]).map { Int($0) },
                fullURL: string(dict, keys: ["full_url"]),
                children: [] // Home chỉ cần root
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

    // MARK: - Private

    private static func eventPageTabsObject(from pageDataJSON: String) -> [[String: Any]]? {
        let trimmed = pageDataJSON.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let data = trimmed.data(using: .utf8),
              let root = jsonObject(data) else { return nil }

        // `{ "tabs": [...] }`
        if let dict = root as? [String: Any] {
            if let tabs = dict["tabs"] as? [[String: Any]] { return tabs }
            // đôi khi bọc thêm
            if let result = dict["result"] as? [String: Any],
               let tabs = result["tabs"] as? [[String: Any]] {
                return tabs
            }
        }
        // `[ { tab }, ... ]`
        if let tabs = root as? [[String: Any]] { return tabs }
        return nil
    }

    /// Object hoặc JSON string → `[String: Any]`.
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

        let id = string(dict, keys: ["id", "product_id", "productId", "sku", "uuid"]) ?? "product-\(fallbackIndex)"
        let name = string(dict, keys: ["name", "title", "product_name", "productName", "label"]) ?? ""
        guard !name.isEmpty else { return nil }

        let unit = string(dict, keys: [
            "unit", "unit_label", "quantity", "qty", "weight",
            "short_description", "shortDescription", "attribute", "variant", "desc",
        ]) ?? ""

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

        return ShopProduct(
            id: id,
            name: name,
            unitLabel: unit.isEmpty ? "1 unit" : unit,
            price: price,
            imageURL: image
        )
    }

    private static func jsonObject(_ data: Data) -> Any? {
        try? JSONSerialization.jsonObject(with: data)
    }

    /// Lấy mảng item từ envelope `{ status, result }` hoặc object có key list.
    private static func arrayPayload(from root: Any, preferredKeys: [String]) -> [Any] {
        if let arr = root as? [Any] { return arr }

        guard let dict = root as? [String: Any] else { return [] }

        let result = dict["result"] ?? dict["data"] ?? dict

        if let arr = result as? [Any] { return arr }

        if let resultDict = result as? [String: Any] {
            for key in preferredKeys {
                if let arr = resultDict[key] as? [Any] { return arr }
            }
            // Một số API bọc thêm 1 lớp
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
            // Relative path trên CDN Printerval — cần absolute sau; tạm bỏ
            return URL(string: "https://printerval.com" + raw)
        }
        return URL(string: raw)
    }
}
