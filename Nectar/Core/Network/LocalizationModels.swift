import Foundation

// MARK: - Envelope result for GET /localization

/// `result` của API localization.
struct LocalizationPayload: Decodable, CustomStringConvertible {
    let defaultLocale: String
    let defaultCurrencyUnit: String
    let locales: [LocaleItem]
    let currencyUnits: [CurrencyUnitItem]
    let hreflangs: [String: String]

    enum CodingKeys: String, CodingKey {
        case defaultLocale = "default_locale"
        case defaultCurrencyUnit = "default_currency_unit"
        case locales
        case currencyUnits = "currency_units"
        case hreflangs
    }

    var description: String {
        "LocalizationPayload(locale: \(defaultLocale), currency: \(defaultCurrencyUnit), locales: \(locales.count))"
    }

    /// Locale đang chọn (default_locale, đã enable).
    var currentLocale: LocaleItem? {
        locales.first { $0.value == defaultLocale && $0.enable }
            ?? locales.first { $0.value == defaultLocale }
            ?? locales.first { $0.enable }
    }

    /// Currency đang chọn theo default_currency_unit.
    var currentCurrency: CurrencyUnitItem? {
        currencyUnits.first { $0.value == defaultCurrencyUnit }
    }

    /// Text UI: "US and Others", "United Kingdom", …
    var displayRegion: String {
        currentLocale?.listText ?? defaultLocale.uppercased()
    }

    static func decode(from data: Data) throws -> LocalizationPayload {
        let decoder = JSONDecoder()
        let envelope = try decoder.decode(APIEnvelope<LocalizationPayload>.self, from: data)
        guard envelope.status == APIConfig.successStatus else {
            throw AppError.network(envelope.message ?? "Localization status ≠ successful")
        }
        guard let result = envelope.result else {
            throw AppError.notFound
        }
        return result
    }
}

// MARK: - Locale row

struct LocaleItem: Decodable, Identifiable, Hashable {
    var id: String { value }

    let value: String
    let text: String
    let lang: String
    let listText: String
    let currencyUnit: String
    let currencyRatio: Double
    let image: String
    let enable: Bool

    enum CodingKeys: String, CodingKey {
        case value, text, lang, image, enable
        case listText = "list_text"
        case currencyUnit = "currency_unit"
        case currencyRatio = "currency_ratio"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        value = try c.decode(String.self, forKey: .value)
        text = try c.decode(String.self, forKey: .text)
        lang = try c.decode(String.self, forKey: .lang)
        listText = try c.decode(String.self, forKey: .listText)
        currencyUnit = try c.decode(String.self, forKey: .currencyUnit)
        image = try c.decode(String.self, forKey: .image)
        enable = try c.decodeIfPresent(Bool.self, forKey: .enable) ?? true

        // API trả Int (1) hoặc Double (0.72…) — decode linh hoạt
        if let ratio = try? c.decode(Double.self, forKey: .currencyRatio) {
            currencyRatio = ratio
        } else if let ratio = try? c.decode(Int.self, forKey: .currencyRatio) {
            currencyRatio = Double(ratio)
        } else {
            currencyRatio = 1
        }
    }
}

// MARK: - Currency row

struct CurrencyUnitItem: Decodable, Identifiable, Hashable {
    var id: String { value }

    let value: String
    let symbol: String
    let symbolText: String
    let template: String

    enum CodingKeys: String, CodingKey {
        case value, symbol, template
        case symbolText = "symbol_text"
    }
}
