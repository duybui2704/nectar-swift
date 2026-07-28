import Foundation

/// Response `/location` — các field optional vì schema API có thể khác nhau.
struct LocationResult: Decodable, CustomStringConvertible {
    let city: String?
    let name: String?
    let country: String?
    let countryCode: String?
    let state: String?
    let address: String?

    enum CodingKeys: String, CodingKey {
        case city, name, country, address, state
        case countryCode = "country_code"
    }

    /// Chuỗi hiển thị trên header Shop (vd: "Hanoi, Vietnam").
    var displayText: String {
        let parts = [city ?? name, state, country]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if parts.isEmpty { return "Unknown location" }
        // city + country là đủ cho UI
        if let city = city ?? name, let country {
            return "\(city), \(country)"
        }
        return parts.joined(separator: ", ")
    }

    var description: String {
        "LocationResult(city: \(city ?? "nil"), country: \(country ?? "nil"), name: \(name ?? "nil"))"
    }

    /// Decode linh hoạt: envelope `{ status, result }` hoặc object trần / array.
    static func decode(from data: Data) throws -> LocationResult? {
        let decoder = JSONDecoder()

        if let envelope = try? decoder.decode(APIEnvelope<LocationResult>.self, from: data),
           let result = envelope.result {
            return result
        }

        if let envelope = try? decoder.decode(APIEnvelope<[LocationResult]>.self, from: data),
           let first = envelope.result?.first {
            return first
        }

        if let direct = try? decoder.decode(LocationResult.self, from: data) {
            return direct
        }

        if let list = try? decoder.decode([LocationResult].self, from: data),
           let first = list.first {
            return first
        }

        // Fallback: đọc dictionary thô để vẫn log / lấy vài key phổ biến
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            let result = (json["result"] as? [String: Any]) ?? json
            return LocationResult(
                city: result["city"] as? String,
                name: result["name"] as? String,
                country: result["country"] as? String,
                countryCode: (result["country_code"] as? String) ?? (result["countryCode"] as? String),
                state: result["state"] as? String,
                address: result["address"] as? String
            )
        }

        return nil
    }
}
