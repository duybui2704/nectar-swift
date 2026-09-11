import Foundation

// MARK: - Core product

struct ProductDetail: Identifiable, Hashable, Sendable {
    let id: String
    /// SKU dùng cho shipping-info / cart — lấy từ product payload sau khi `product/{id}` xong.
    let skuId: String?
    let name: String
    let sellerName: String
    let displayPrice: String
    let compareAtPrice: String?
    let rating: Double?
    let reviewCount: Int?
    let inStock: Bool
    let currencySymbol: String
    /// Ảnh chính từ product payload — seed gallery khi `gallery` API trống.
    let imageURL: URL?
    /// Slug web (vd. `cool-tee-p123`) — dùng build share URL khi API không trả permalink.
    let slug: String?
    /// Permalink đầy đủ từ API nếu có.
    let productURL: URL?

    /// URL ưu tiên để share (web → slug → deep link app).
    var shareURL: URL {
        if let productURL { return productURL }
        if let slug, !slug.isEmpty {
            let path = slug.hasPrefix("/") ? String(slug.dropFirst()) : slug
            if let url = URL(string: "https://printerval.com/\(path)") {
                return url
            }
        }
        return URL(string: "nectar://product/\(id)")!
    }
}

enum ProductDetailPhase: Equatable {
    case idle
    case loading
    case ready
    case failed(message: String)
}

struct ProductGalleryItem: Identifiable, Hashable, Sendable {
    let id: String
    let imageURL: URL?
    let isVideo: Bool
}

// MARK: - Variants

struct ProductColorOption: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let hex: String?
    let imageURL: URL?
}

struct ProductOptionChip: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
}

struct ProductStyleOption: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let priceLabel: String?
}

struct ProductPrintLocation: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let iconSystemName: String
}

struct ProductVariantState: Hashable, Sendable {
    var colors: [ProductColorOption] = []
    var types: [ProductOptionChip] = []
    var styles: [ProductStyleOption] = []
    var sizes: [ProductOptionChip] = []
    var printLocations: [ProductPrintLocation] = []

    var selectedColorId: String?
    var selectedTypeId: String?
    var selectedStyleId: String?
    var selectedSizeId: String?
    var selectedPrintId: String?

    var selectedColorName: String {
        colors.first(where: { $0.id == selectedColorId })?.name ?? colors.first?.name ?? "—"
    }

    var selectedTypeName: String {
        types.first(where: { $0.id == selectedTypeId })?.title ?? types.first?.title ?? "—"
    }

    var selectedSizeName: String {
        sizes.first(where: { $0.id == selectedSizeId })?.title ?? sizes.first?.title ?? "—"
    }

    var selectedPrintName: String {
        printLocations.first(where: { $0.id == selectedPrintId })?.title ?? printLocations.first?.title ?? "—"
    }

    var selectedStyleName: String {
        guard let style = selectedStyle else { return "—" }
        if let price = style.priceLabel, !price.isEmpty {
            return "\(style.title) | \(price)"
        }
        return style.title
    }

    var selectedStyle: ProductStyleOption? {
        styles.first(where: { $0.id == selectedStyleId }) ?? styles.first
    }

    mutating func applyDefaults() {
        if selectedColorId == nil { selectedColorId = colors.first?.id }
        if selectedTypeId == nil { selectedTypeId = types.first?.id }
        if selectedStyleId == nil { selectedStyleId = styles.first?.id }
        if selectedSizeId == nil { selectedSizeId = sizes.first?.id }
        if selectedPrintId == nil { selectedPrintId = printLocations.first?.id }
    }
}

// MARK: - Secondary

struct ProductBulkPriceHint: Hashable, Sendable {
    let summary: String
}

struct BoughtTogetherItem: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let displayPrice: String
    let imageURL: URL?
    var isSelected: Bool
}


// MARK: - ProductByCate
struct ProductByCate: Codable, Hashable, Sendable {
    /// Dynamic cate → product id map; ignore unknown keys from API.
    private struct DynamicKeys: CodingKey {
        var stringValue: String
        init?(stringValue: String) { self.stringValue = stringValue }
        var intValue: Int? { Int(stringValue) }
        init?(intValue: Int) { stringValue = String(intValue) }
    }

    let values: [String: Int]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicKeys.self)
        var mapped: [String: Int] = [:]
        for key in container.allKeys {
            if let value = try? container.decode(Int.self, forKey: key) {
                mapped[key.stringValue] = value
            }
        }
        values = mapped
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicKeys.self)
        for (key, value) in values {
            guard let codingKey = DynamicKeys(stringValue: key) else { continue }
            try container.encode(value, forKey: codingKey)
        }
    }
}

// MARK: - ShippingByCate
struct ShippingByCate: Codable, Hashable, Sendable {}

// MARK: - TaxByProduct
struct TaxByProduct: Codable, Hashable, Sendable {
    let productID: Int?
    let productSkuID: Int?
    let tax: Int?

    enum CodingKeys: String, CodingKey {
        case productID = "product_id"
        case productSkuID = "product_sku_id"
        case tax
    }
}

// MARK: - AdditionalInfo
struct AdditionalInfo: Codable, Hashable, Sendable {
    let feeLimit: Int?
    let feeIfLimit: Int?
    let addingFee: Int?
    let cateName: String?

    enum CodingKeys: String, CodingKey {
        case feeLimit = "fee_limit"
        case feeIfLimit = "fee_if_limit"
        case addingFee = "adding_fee"
        case cateName = "cate_name"
    }
}

/// Một option trong `result` của shipping-info (vd. key `"standard"`).
struct ShippingInfo: Codable, Hashable, Sendable {
    let nameShipping: String?
    let type: String?
    let id: Int?
    let shippingFee: Double?
    let defaultMinTime: Int?
    let defaultMaxTime: Int?
    let handlingMinTime: Int?
    let handlingMaxTime: Int?
    let deliveryMinTime: Int?
    let deliveryMaxTime: Int?
    let location: String?
    let warehouseID: Int?
    let warehouseName: String?
    let taxByProducts: [TaxByProduct]?
    let shippingByCate: ShippingByCate?
    let additionalInfo: [AdditionalInfo]?
    let productByCate: ProductByCate?
    let indexSort: Int?

    enum CodingKeys: String, CodingKey {
        case nameShipping = "name_shipping"
        case type
        case id
        case shippingFee = "shipping_fee"
        case defaultMinTime = "default_min_time"
        case defaultMaxTime = "default_max_time"
        case handlingMinTime = "handling_min_time"
        case handlingMaxTime = "handling_max_time"
        case deliveryMinTime = "delivery_min_time"
        case deliveryMaxTime = "delivery_max_time"
        case location
        case warehouseID = "warehouse_id"
        case warehouseName = "warehouse_name"
        case taxByProducts = "tax_by_products"
        case shippingByCate = "shipping_by_cate"
        case additionalInfo = "additional_info"
        case productByCate = "product_by_cate"
        case indexSort = "index_sort"
    }
}

struct ProductDetailSnapshot: Sendable {
    var product: ProductDetail?
    var gallery: [ProductGalleryItem] = []
    var variants: ProductVariantState = .init()
    var bulkPriceHint: ProductBulkPriceHint?
    var relatedProducts: [ShopProduct] = []
    var recommendationProducts: [ShopProduct] = []
    var boughtTogether: [BoughtTogetherItem] = []
    var shipping: ShippingInfo?
}
