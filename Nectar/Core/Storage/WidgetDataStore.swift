import Foundation

/// Shared balance snapshot for WidgetKit / App Group (demo).
enum WidgetDataStore {
    static let appGroupID = "group.com.example.Nectar"
    private static let balanceKey = "widgetBalanceVND"

    static func updateBalance(_ amount: Decimal) {
        UserDefaults(suiteName: appGroupID)?.set("\(amount)", forKey: balanceKey)
        UserDefaults.standard.set("\(amount)", forKey: balanceKey)
    }

    static var balanceText: String {
        let raw = UserDefaults(suiteName: appGroupID)?.string(forKey: balanceKey)
            ?? UserDefaults.standard.string(forKey: balanceKey)
        guard let raw, let decimal = Decimal(string: raw) else {
            return MoneyFormatter.format(0)
        }
        return MoneyFormatter.format(decimal)
    }
}
