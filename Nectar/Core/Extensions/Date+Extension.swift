import Foundation

extension Date {

    func addingDays(_ days: Int) -> Date? {
        Calendar.current.date(
            byAdding: .day,
            value: days,
            to: self
        )
    }

    func formattedMonthDay() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")

        return formatter.string(from: self)
    }
}
