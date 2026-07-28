import Foundation
import Combine

/// Cache localization toàn app (locales, currency, hreflang).
@MainActor
final class LocalizationStore: ObservableObject {
    static let shared = LocalizationStore()

    @Published private(set) var payload: LocalizationPayload?
    @Published private(set) var selectedLocaleCode: String = AppIdentity.country

    var currentLocale: LocaleItem? {
        guard let payload else { return nil }
        return payload.locales.first { $0.value == selectedLocaleCode && $0.enable }
            ?? payload.currentLocale
    }

    var currentCurrency: CurrencyUnitItem? {
        guard let payload else { return nil }
        let unit = currentLocale?.currencyUnit ?? payload.defaultCurrencyUnit
        return payload.currencyUnits.first { $0.value == unit }
    }

    /// Text region cho header Shop, vd: "US and Others".
    var displayRegion: String {
        currentLocale?.listText ?? payload?.displayRegion ?? "US and Others"
    }

    var displayCurrencyCode: String {
        currentCurrency?.value ?? payload?.defaultCurrencyUnit ?? "USD"
    }

    func apply(_ payload: LocalizationPayload) {
        self.payload = payload
        selectedLocaleCode = payload.defaultLocale
        #if DEBUG
        print("🌐 LocalizationStore:", payload)
        print("🌐 region:", displayRegion, "| currency:", displayCurrencyCode)
        #endif
    }

    func selectLocale(_ code: String) {
        guard payload?.locales.contains(where: { $0.value == code && $0.enable }) == true else { return }
        selectedLocaleCode = code
    }
}
