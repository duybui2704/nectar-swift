import Foundation

// MARK: - Core product

struct ProductDetail: Identifiable, Hashable, Sendable {
    let id: String
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

struct ProductDetailSnapshot: Sendable {
    var product: ProductDetail?
    var gallery: [ProductGalleryItem] = []
    var variants: ProductVariantState = .init()
    var bulkPriceHint: ProductBulkPriceHint?
    var relatedProducts: [ShopProduct] = []
    var recommendationProducts: [ShopProduct] = []
    var boughtTogether: [BoughtTogetherItem] = []
}
