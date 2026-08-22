import Foundation

enum DateUtils {

    static func addingDays(
        _ days: Int,
        from date: Date = Date()
    ) -> Date? {
        Calendar.current.date(
            byAdding: .day,
            value: days,
            to: date
        )
    }

    static func formatMonthDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        return formatter.string(from: date)
    }

    static func deliveryWindow(
        minDays: Int,
        maxDays: Int,
        from date: Date = Date()
    ) -> String {

        guard
            let minDate = addingDays(minDays, from: date),
            let maxDate = addingDays(maxDays, from: date)
        else {
            return ""
        }

        return "\(formatMonthDay(minDate)) – \(formatMonthDay(maxDate))"
    }
}
