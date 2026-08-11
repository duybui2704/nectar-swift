// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let favourite = try? JSONDecoder().decode(Favourite.self, from: jsonData)

import Foundation

// MARK: - Favourite
struct Favourite: Codable, Identifiable {
    let id: Int
    let status: String
    let configurations: JSONNull?
    let productID, productSkuID: Int
    let product: ProductFav

    enum CodingKeys: String, CodingKey {
        case id, status, configurations
        case productID = "productId"
        case productSkuID = "productSkuId"
        case product
    }
}

// MARK: - Product
struct ProductFav: Codable {
    let id: Int
    let sku, name, slug: String
    let brandID: Int
    let imageURL: String
    let price, highPrice: Double
    let addShippingFee: Int
    let status, description, content: String
    let weight: Int
    let note: String
    let inventory, sold, viewCount: Int
    let updatedAt, createdAt: String
    let deletedAt: JSONNull?
    let barcode, statusOutStock: String
    let podParentID: Int
    let trademarks: JSONNull?
    let isTrademark, approveAdvertising: Int
    let gtin: JSONNull?
    let ratingCount: Int
    let ratingValue: Double
    let actorID, updaterID: Int
    let isHidden: String
    let isViolation, isAlwaysOnAds: Int
    let user: User

    enum CodingKeys: String, CodingKey {
        case id, sku, name, slug
        case brandID = "brandId"
        case imageURL = "imageUrl"
        case price, highPrice, addShippingFee, status, description, content, weight, note, inventory, sold, viewCount, updatedAt, createdAt, deletedAt, barcode, statusOutStock
        case podParentID = "podParentId"
        case trademarks, isTrademark, approveAdvertising, gtin, ratingCount, ratingValue
        case actorID = "actorId"
        case updaterID = "updaterId"
        case isHidden, isViolation, isAlwaysOnAds, user
    }
}

// MARK: - User
struct User: Codable {
    let id: Int
    let name, slug: String
    let imageAvatar: String
    let productID: Int

    enum CodingKeys: String, CodingKey {
        case id, name, slug, imageAvatar
        case productID = "productId"
    }
}

// MARK: - Encode/decode helpers

class JSONNull: Codable, Hashable {

    public static func == (lhs: JSONNull, rhs: JSONNull) -> Bool {
        return true
    }

    public var hashValue: Int {
        return 0
    }

    public func hash(into hasher: inout Hasher) {
        // No-op
    }

    public init() {}

    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if !container.decodeNil() {
            throw DecodingError.typeMismatch(JSONNull.self, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for JSONNull"))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}
