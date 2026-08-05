import Foundation

// MARK: - ChildChild
struct ChildChild: Codable {
    let id: Int
    let name: String
    let type: TypeEnum
    let parentID: Int
    let imageURL: String?
    let slug: String
    let lft, rgt: Int
    let fullURL: String
    let children: [CategoryTree]

    enum CodingKeys: String, CodingKey {
        case id, name, type
        case parentID = "parent_id"
        case imageURL = "image_url"
        case slug, lft, rgt
        case fullURL = "full_url"
        case children
    }
}

// MARK: - CategoryTreeChild
struct CategoryTreeChild: Codable {
    let id: Int
    let name: String
    let type: TypeEnum
    let parentID: Int
    let imageURL: String
    let slug: String
    let lft, rgt: Int
    let fullURL: String
    let children: [ChildChild]

    enum CodingKeys: String, CodingKey {
        case id, name, type
        case parentID = "parent_id"
        case imageURL = "image_url"
        case slug, lft, rgt
        case fullURL = "full_url"
        case children
    }
}

// MARK: - CategoryTree
struct CategoryTree: Codable {
    let id: Int
    let name: String
    let type: TypeEnum
    let parentID: Int?
    let imageURL: String?
    let slug: String
    let lft, rgt: Int
    let fullURL: String
    let children: [CategoryTreeChild]

    enum CodingKeys: String, CodingKey {
        case id, name, type
        case parentID = "parent_id"
        case imageURL = "image_url"
        case slug, lft, rgt
        case fullURL = "full_url"
        case children
    }
}

enum TypeEnum: String, Codable {
    case product = "PRODUCT"
}

extension CategoryTree {
    /// `imageURL` là `String?` từ API — UI cần `URL?`.
    var resolvedImageURL: URL? {
        guard let raw = imageURL?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else { return nil }
        if raw.hasPrefix("//") { return URL(string: "https:" + raw) }
        if raw.hasPrefix("/") { return URL(string: "https://printerval.com" + raw) }
        return URL(string: raw)
    }
}
