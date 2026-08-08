import Foundation

/// Map raw Printerval JSON → domain models (flexible keys — Cloudflare thường chặn curl sample).
enum ProductDTOMapper {

    // MARK: - Product

    static func product(from data: Data, fallbackId: String) -> ProductDetail? {
        guard let root = jsonObject(data) else {
            logParseFailure(fallbackId, reason: "invalid JSON", data: data)
            return nil
        }

        if let dict = root as? [String: Any],
           let status = string(dict, keys: ["status"]),
           !isSuccessStatus(status) {
            logParseFailure(
                fallbackId,
                reason: "API status=\(status) message=\(string(dict, keys: ["message", "error", "msg"]) ?? "")",
                data: data
            )
        }

        guard let payload = productPayload(from: root) else {
            logParseFailure(fallbackId, reason: "no product payload", data: data)
            return nil
        }

        let id = string(payload, keys: ["id", "product_id", "productId", "design_id", "designId"]) ?? fallbackId
        let rawName = string(payload, keys: [
            "name", "title", "product_name", "productName", "label",
            "short_name", "shortName", "display_name", "displayName",
        ]) ?? ""
        let name = stripHTML(rawName).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            logParseFailure(fallbackId, reason: "empty name; keys=\(Array(payload.keys).sorted())", data: data)
            return nil
        }

        let sellerDict = nested(payload, keys: ["seller", "designer", "shop", "store", "vendor_info"])
            ?? nested(rootDict(root) ?? [:], keys: ["seller", "designer", "shop", "store"])
        let seller = string(payload, keys: [
            "seller_name", "sellerName", "designer_name", "designerName",
            "shop_name", "shopName", "vendor", "brand", "author",
        ]) ?? string(sellerDict ?? [:], keys: ["name", "title", "username"])
            ?? "Printerval"

        let displayPrice = string(payload, keys: [
            "display_price", "displayPrice", "price_text", "priceText",
            "formatted_price", "formattedPrice", "price_format",
        ]) ?? formatPrice(number(payload, keys: [
            "price", "sale_price", "salePrice", "final_price", "finalPrice", "min_price", "minPrice",
        ]))

        let compare = string(payload, keys: [
            "compare_at_price", "compareAtPrice", "original_price", "originalPrice",
            "old_price", "oldPrice", "regular_price", "list_price",
        ]) ?? formatPrice(number(payload, keys: [
            "compare_at_price", "original_price", "old_price", "regular_price",
        ]))

        let rating = number(payload, keys: [
            "rating", "avg_rating", "average_rating", "averageRating", "star", "stars", "rate",
        ])
        let reviews = int(payload, keys: [
            "review_count", "reviewCount", "reviews", "total_reviews", "num_reviews", "comment_count",
        ])
        let stock = bool(payload, keys: ["in_stock", "inStock", "available", "is_available", "isAvailable"])
            ?? {
                let status = (string(payload, keys: ["stock_status", "stockStatus"]) ?? "").lowercased()
                if status.isEmpty { return true }
                return !status.contains("out")
            }()

        let currency = string(payload, keys: ["currency_symbol", "currencySymbol", "symbol", "currency"]) ?? "$"
        let imageURL = url(payload, keys: [
            "image", "image_url", "imageUrl", "thumbnail", "thumb",
            "photo", "cover", "main_image", "mainImage", "feature_image",
        ])

        return ProductDetail(
            id: id,
            name: name,
            sellerName: seller,
            displayPrice: displayPrice.isEmpty ? "—" : displayPrice,
            compareAtPrice: compare.isEmpty ? nil : compare,
            rating: rating,
            reviewCount: reviews,
            inStock: stock,
            currencySymbol: currency,
            imageURL: imageURL
        )
    }

    /// Ưu tiên dict có `name`/`title` — hỗ trợ `result.product`, `data.product`, …
    private static func productPayload(from root: Any) -> [String: Any]? {
        let rootDict = root as? [String: Any]

        var candidates: [[String: Any]] = []
        if let dict = rootDict {
            if let result = dict["result"] as? [String: Any] {
                candidates.append(result)
                if let product = result["product"] as? [String: Any] { candidates.append(product) }
                if let item = result["item"] as? [String: Any] { candidates.append(item) }
            }
            if let dataObj = dict["data"] as? [String: Any] {
                candidates.append(dataObj)
                if let product = dataObj["product"] as? [String: Any] { candidates.append(product) }
            }
            if let product = dict["product"] as? [String: Any] { candidates.append(product) }
            candidates.append(dict)
        }

        let nameKeys = ["name", "title", "product_name", "productName", "short_name", "display_name"]
        for candidate in candidates {
            if string(candidate, keys: nameKeys) != nil { return candidate }
        }
        return candidates.first
    }

    private static func rootDict(_ root: Any) -> [String: Any]? {
        root as? [String: Any]
    }

    private static func isSuccessStatus(_ status: String) -> Bool {
        ["successful", "success", "ok", "1"].contains(status.lowercased())
    }

    private static func stripHTML(_ value: String) -> String {
        value.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }

    private static func logParseFailure(_ id: String, reason: String, data: Data) {
        let preview = String(data: data, encoding: .utf8).map { String($0.prefix(600)) } ?? "<binary>"
        NectarLog.log(
            "⚠️ ProductDTOMapper product(\(id)): \(reason)\n\(preview)",
            title: "Product"
        )
    }

    // MARK: - Gallery

    static func gallery(from data: Data) -> [ProductGalleryItem] {
        let items = arrayPayload(from: data, preferredKeys: [
            "gallery", "images", "items", "media", "photos", "result",
        ])

        return items.enumerated().compactMap { index, item -> ProductGalleryItem? in
            if let s = item as? String {
                guard let imageURL = makeURL(s) else { return nil }
                return ProductGalleryItem(id: "g-\(index)", imageURL: imageURL, isVideo: false)
            }

            guard let dict = item as? [String: Any] else { return nil }

            let id = string(dict, keys: ["id", "uuid", "media_id"]) ?? "g-\(index)"
            let imageURL = url(dict, keys: ["url", "src", "image", "image_url", "imageUrl", "path", "thumbnail"])
            let type = (string(dict, keys: ["type", "media_type", "mediaType"]) ?? "").lowercased()
            let isVideo = type.contains("video")
                || bool(dict, keys: ["is_video", "isVideo", "video"]) == true
                || url(dict, keys: ["video_url", "videoUrl"]) != nil

            guard imageURL != nil || isVideo else { return nil }
            return ProductGalleryItem(id: id, imageURL: imageURL, isVideo: isVideo)
        }
    }

    // MARK: - Variant

    static func variants(from data: Data) -> ProductVariantState {
        guard let root = unwrapDict(data) else { return .init() }

        var state = ProductVariantState()

        let colorsSource = array(from: root, keys: [
            "colors", "color", "color_options", "colorOptions", "swatches",
        ])
        state.colors = colorsSource.enumerated().compactMap { index, item in
            guard let dict = asDict(item) else { return nil }
            let id = string(dict, keys: ["id", "value", "code", "sku"]) ?? "color-\(index)"
            let name = string(dict, keys: ["name", "title", "label", "color_name"]) ?? "Color \(index + 1)"
            return ProductColorOption(
                id: id,
                name: name,
                hex: string(dict, keys: ["hex", "color", "code", "value"]),
                imageURL: url(dict, keys: ["image", "image_url", "imageUrl", "thumbnail", "swatch"])
            )
        }

        let typesSource = array(from: root, keys: ["types", "type", "genders", "gender", "audiences"])
        state.types = chips(from: typesSource, prefix: "type")

        let stylesSource = array(from: root, keys: ["styles", "style", "products", "style_options"])
        state.styles = stylesSource.enumerated().compactMap { index, item in
            guard let dict = asDict(item) else { return nil }
            let id = string(dict, keys: ["id", "value", "sku", "product_id"]) ?? "style-\(index)"
            let title = string(dict, keys: ["name", "title", "label", "style_name"]) ?? "Style \(index + 1)"
            let price = string(dict, keys: ["display_price", "price_text", "price"])
                ?? formatPrice(number(dict, keys: ["price", "sale_price"]))
            return ProductStyleOption(id: id, title: title, priceLabel: price.isEmpty ? nil : price)
        }

        let sizesSource = array(from: root, keys: ["sizes", "size", "size_options", "sizeOptions"])
        state.sizes = chips(from: sizesSource, prefix: "size")

        let printSource = array(from: root, keys: [
            "print_locations", "printLocations", "prints", "print_areas", "locations",
        ])
        state.printLocations = printSource.enumerated().compactMap { index, item in
            guard let dict = asDict(item) else {
                if let s = item as? String {
                    return ProductPrintLocation(id: "print-\(index)", title: s, iconSystemName: printIcon(for: s))
                }
                return nil
            }
            let id = string(dict, keys: ["id", "value", "code"]) ?? "print-\(index)"
            let title = string(dict, keys: ["name", "title", "label"]) ?? "Print \(index + 1)"
            return ProductPrintLocation(id: id, title: title, iconSystemName: printIcon(for: title))
        }

        // Nested attributes fallback (format=1 often wraps options)
        if state.colors.isEmpty || state.sizes.isEmpty {
            let attrs = array(from: root, keys: ["attributes", "options", "variants", "variant_options"])
            for attr in attrs {
                guard let dict = asDict(attr) else { continue }
                let key = (string(dict, keys: ["code", "key", "name", "type", "attribute"]) ?? "").lowercased()
                let values = array(from: dict, keys: ["values", "options", "items", "choices"])
                if key.contains("color"), state.colors.isEmpty {
                    state.colors = values.enumerated().compactMap { index, item in
                        guard let d = asDict(item) else { return nil }
                        let id = string(d, keys: ["id", "value"]) ?? "color-\(index)"
                        let name = string(d, keys: ["name", "title", "label"]) ?? "Color \(index + 1)"
                        return ProductColorOption(
                            id: id,
                            name: name,
                            hex: string(d, keys: ["hex", "color", "code"]),
                            imageURL: url(d, keys: ["image", "image_url", "thumbnail"])
                        )
                    }
                } else if key.contains("size"), state.sizes.isEmpty {
                    state.sizes = chips(from: values, prefix: "size")
                } else if (key.contains("type") || key.contains("gender")), state.types.isEmpty {
                    state.types = chips(from: values, prefix: "type")
                } else if key.contains("style"), state.styles.isEmpty {
                    state.styles = values.enumerated().compactMap { index, item in
                        guard let d = asDict(item) else { return nil }
                        let id = string(d, keys: ["id", "value"]) ?? "style-\(index)"
                        let title = string(d, keys: ["name", "title", "label"]) ?? "Style \(index + 1)"
                        let price = string(d, keys: ["display_price", "price"])
                            ?? formatPrice(number(d, keys: ["price"]))
                        return ProductStyleOption(id: id, title: title, priceLabel: price.isEmpty ? nil : price)
                    }
                }
            }
        }

        if state.printLocations.isEmpty {
            state.printLocations = [
                .init(id: "front", title: "Front", iconSystemName: "tshirt"),
                .init(id: "back", title: "Back", iconSystemName: "tshirt"),
                .init(id: "sleeve", title: "Sleeve", iconSystemName: "tshirt"),
                .init(id: "both", title: "Both", iconSystemName: "tshirt"),
            ]
        }

        state.applyDefaults()
        return state
    }

    // MARK: - Bulk / rails / bought-together

    static func bulkPriceHint(from data: Data) -> ProductBulkPriceHint? {
        guard let root = unwrapDict(data) else { return nil }

        if let summary = string(root, keys: ["summary", "message", "hint", "text", "description"]) {
            return ProductBulkPriceHint(summary: summary)
        }

        let tiers = array(from: root, keys: ["tiers", "prices", "bulk_prices", "items", "result"])
        guard let first = tiers.first.flatMap(asDict) else { return nil }
        let qty = string(first, keys: ["quantity", "qty", "min", "from"]) ?? "20+"
        let price = string(first, keys: ["display_price", "price_text", "price"])
            ?? formatPrice(number(first, keys: ["price", "unit_price"]))
        guard !price.isEmpty else { return nil }
        return ProductBulkPriceHint(summary: "\(price) each for \(qty) items")
    }

    static func products(from data: Data) -> [ShopProduct] {
        HomeDTOMapper.products(from: data)
    }

    static func boughtTogether(from data: Data) -> [BoughtTogetherItem] {
        let items = arrayPayload(from: data, preferredKeys: [
            "items", "products", "bought_together", "result", "data",
        ])

        return items.enumerated().compactMap { index, item in
            guard let dict = asDict(item) else { return nil }
            let product = dict["product"] as? [String: Any] ?? dict
            let id = string(product, keys: ["id", "product_id", "productId"]) ?? "bt-\(index)"
            let name = string(product, keys: ["name", "title"]) ?? ""
            guard !name.isEmpty else { return nil }
            let price = string(product, keys: ["display_price", "displayPrice", "price_text"])
                ?? formatPrice(number(product, keys: ["price", "sale_price", "final_price"]))
            return BoughtTogetherItem(
                id: id,
                name: name,
                displayPrice: price.isEmpty ? "—" : price,
                imageURL: url(product, keys: ["image", "image_url", "imageUrl", "thumbnail", "thumb"]),
                isSelected: true
            )
        }
    }

    // MARK: - Helpers

    private static func chips(from items: [Any], prefix: String) -> [ProductOptionChip] {
        items.enumerated().compactMap { index, item in
            if let s = item as? String {
                return ProductOptionChip(id: "\(prefix)-\(s)", title: s)
            }
            guard let dict = asDict(item) else { return nil }
            let id = string(dict, keys: ["id", "value", "code"]) ?? "\(prefix)-\(index)"
            let title = string(dict, keys: ["name", "title", "label", "value"]) ?? "\(prefix) \(index + 1)"
            return ProductOptionChip(id: id, title: title)
        }
    }

    private static func printIcon(for title: String) -> String {
        let t = title.lowercased()
        if t.contains("back") { return "rectangle.portrait" }
        if t.contains("sleeve") { return "rectangle.portrait.on.rectangle.portrait" }
        if t.contains("both") { return "square.on.square" }
        return "tshirt"
    }

    private static func unwrapDict(_ data: Data) -> [String: Any]? {
        guard let root = jsonObject(data) else { return nil }
        if let dict = root as? [String: Any] {
            if let result = dict["result"] as? [String: Any] { return result }
            if let dataObj = dict["data"] as? [String: Any] { return dataObj }
            if let product = dict["product"] as? [String: Any] { return product }
            return dict
        }
        return nil
    }

    private static func arrayPayload(from data: Data, preferredKeys: [String]) -> [Any] {
        guard let root = jsonObject(data) else { return [] }
        if let arr = root as? [Any] { return arr }
        guard let dict = root as? [String: Any] else { return [] }

        for key in preferredKeys {
            if let arr = dict[key] as? [Any] { return arr }
        }

        if let result = dict["result"] {
            if let arr = result as? [Any] { return arr }
            if let d = result as? [String: Any] {
                for key in preferredKeys {
                    if let arr = d[key] as? [Any] { return arr }
                }
            }
        }
        if let dataObj = dict["data"] {
            if let arr = dataObj as? [Any] { return arr }
            if let d = dataObj as? [String: Any] {
                for key in preferredKeys {
                    if let arr = d[key] as? [Any] { return arr }
                }
            }
        }
        return []
    }

    private static func array(from dict: [String: Any], keys: [String]) -> [Any] {
        for key in keys {
            if let arr = dict[key] as? [Any] { return arr }
        }
        return []
    }

    private static func nested(_ dict: [String: Any], keys: [String]) -> [String: Any]? {
        for key in keys {
            if let nested = dict[key] as? [String: Any] { return nested }
        }
        return nil
    }

    private static func asDict(_ item: Any) -> [String: Any]? {
        item as? [String: Any]
    }

    private static func jsonObject(_ data: Data) -> Any? {
        try? JSONSerialization.jsonObject(with: data)
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

    private static func int(_ dict: [String: Any], keys: [String]) -> Int? {
        number(dict, keys: keys).map { Int($0) }
    }

    private static func bool(_ dict: [String: Any], keys: [String]) -> Bool? {
        for key in keys {
            if let b = dict[key] as? Bool { return b }
            if let n = dict[key] as? NSNumber { return n.boolValue }
            if let s = dict[key] as? String {
                switch s.lowercased() {
                case "1", "true", "yes", "y": return true
                case "0", "false", "no", "n": return false
                default: break
                }
            }
        }
        return nil
    }

    private static func url(_ dict: [String: Any], keys: [String]) -> URL? {
        guard let raw = string(dict, keys: keys) else { return nil }
        return makeURL(raw)
    }

    private static func makeURL(_ raw: String) -> URL? {
        if raw.hasPrefix("//") { return URL(string: "https:" + raw) }
        if raw.hasPrefix("/") { return URL(string: "https://printerval.com" + raw) }
        return URL(string: raw)
    }

    private static func formatPrice(_ value: Double?) -> String {
        guard let value, value > 0 else { return "" }
        if value == floor(value) { return String(format: "$%.0f", value) }
        return String(format: "$%.2f", value)
    }
}
