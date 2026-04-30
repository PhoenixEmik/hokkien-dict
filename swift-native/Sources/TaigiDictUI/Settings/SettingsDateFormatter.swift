import Foundation

public protocol SettingsDateFormatting {
    func displayString(from iso8601: String?) -> String?
}

public struct SettingsDateFormatter: SettingsDateFormatting {
    private let locale: Locale
    private let timeZone: TimeZone

    public init(locale: Locale = .autoupdatingCurrent, timeZone: TimeZone = .autoupdatingCurrent) {
        self.locale = locale
        self.timeZone = timeZone
    }

    public func displayString(from iso8601: String?) -> String? {
        guard let iso8601, !iso8601.isEmpty else {
            return nil
        }

        guard let date = parseISO8601(iso8601) else {
            return iso8601
        }

        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func parseISO8601(_ value: String) -> Date? {
        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime]

        if let date = parser.date(from: value) {
            return date
        }

        parser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return parser.date(from: value)
    }
}
