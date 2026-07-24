import WidgetKit
import SwiftUI

// Standalone widget extension — reads balance from App Group / fallback UserDefaults.

private enum WidgetBalanceReader {
    static let balanceKey = "widgetBalanceVND"

    static var text: String {
        let raw = UserDefaults(suiteName: "group.com.example.Nectar")?.string(forKey: balanceKey)
            ?? UserDefaults.standard.string(forKey: balanceKey)
        guard let raw, let value = Decimal(string: raw) else { return "—" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "VND"
        formatter.currencySymbol = "₫"
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter.string(from: value as NSDecimalNumber) ?? "\(value) ₫"
    }
}

struct BalanceWidgetEntry: TimelineEntry {
    let date: Date
    let balanceText: String
}

struct BalanceWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> BalanceWidgetEntry {
        BalanceWidgetEntry(date: .now, balanceText: "48.250.000 ₫")
    }

    func getSnapshot(in context: Context, completion: @escaping (BalanceWidgetEntry) -> Void) {
        completion(BalanceWidgetEntry(date: .now, balanceText: WidgetBalanceReader.text))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BalanceWidgetEntry>) -> Void) {
        let entry = BalanceWidgetEntry(date: .now, balanceText: WidgetBalanceReader.text)
        completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(900))))
    }
}

struct BalanceWidgetView: View {
    let entry: BalanceWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Nectar")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(entry.balanceText)
                .font(.headline)
                .minimumScaleFactor(0.7)
            Text("Ví thanh toán")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct BalanceWidget: Widget {
    let kind = "BalanceWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BalanceWidgetProvider()) { entry in
            BalanceWidgetView(entry: entry)
        }
        .configurationDisplayName("Số dư ví")
        .description("Hiển thị số dư checking demo.")
        .supportedFamilies([.systemSmall, .accessoryRectangular])
    }
}

@main
struct NectarWidgetBundle: WidgetBundle {
    var body: some Widget {
        BalanceWidget()
    }
}
