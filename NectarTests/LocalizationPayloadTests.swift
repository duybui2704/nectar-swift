import XCTest
@testable import Nectar

final class LocalizationPayloadTests: XCTestCase {
    func testDecodeLocalizationEnvelope() throws {
        let json = """
        {
          "status": "successful",
          "result": {
            "default_locale": "us",
            "default_currency_unit": "USD",
            "locales": [
              {
                "value": "us",
                "text": "US",
                "lang": "en",
                "list_text": "US and Others",
                "currency_unit": "USD",
                "currency_ratio": 1,
                "image": "/modules/localization/images/us.svg",
                "enable": true
              }
            ],
            "currency_units": [
              {
                "value": "USD",
                "symbol": "$",
                "symbol_text": "US Dollar",
                "template": "${money}{.}{2}"
              }
            ],
            "hreflangs": { "us": "en" }
          }
        }
        """.data(using: .utf8)!

        let payload = try LocalizationPayload.decode(from: json)
        XCTAssertEqual(payload.defaultLocale, "us")
        XCTAssertEqual(payload.displayRegion, "US and Others")
        XCTAssertEqual(payload.currentCurrency?.symbol, "$")
        XCTAssertEqual(payload.locales.first?.currencyRatio, 1)
    }
}
