import Foundation

enum MoneyFormatter {
    static let vnd: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "VND"
        formatter.currencySymbol = "₫"
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter
    }()

    static func format(_ amount: Decimal, currency: String = "VND") -> String {
        if currency == "VND" {
            return vnd.string(from: amount as NSDecimalNumber) ?? "\(amount) ₫"
        }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }
}
