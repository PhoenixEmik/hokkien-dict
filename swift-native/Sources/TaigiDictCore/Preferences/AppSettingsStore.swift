import Foundation

public struct AppSettingsSnapshot: Equatable, Sendable {
    public static let minReadingTextScale = 0.9
    public static let maxReadingTextScale = 1.4
    public static let readingTextScaleDivisions = 5

    public var themePreference: AppThemePreference
    public var readingTextScale: Double

    public init(
        themePreference: AppThemePreference = .system,
        readingTextScale: Double = 1.0
    ) {
        self.themePreference = themePreference
        self.readingTextScale = Self.snapReadingTextScale(readingTextScale)
    }

    public static func snapReadingTextScale(_ value: Double) -> Double {
        let step = (maxReadingTextScale - minReadingTextScale) / Double(readingTextScaleDivisions)
        let clamped = min(max(value, minReadingTextScale), maxReadingTextScale)
        let snapped = minReadingTextScale + ((clamped - minReadingTextScale) / step).rounded() * step
        return (snapped * 100).rounded() / 100
    }
}

public protocol AppSettingsStoring: Sendable {
    func load() async -> AppSettingsSnapshot
    func setThemePreference(_ preference: AppThemePreference) async
    func setReadingTextScale(_ value: Double) async
}

public actor UserDefaultsAppSettingsStore: AppSettingsStoring {
    public static let themePreferenceKey = "theme_preference"
    public static let readingTextScaleKey = "reading_text_scale"

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func load() async -> AppSettingsSnapshot {
        let theme = AppThemePreference(rawValue: defaults.string(forKey: Self.themePreferenceKey) ?? "") ?? .system
        let scale = defaults.object(forKey: Self.readingTextScaleKey) as? Double ?? 1.0

        return AppSettingsSnapshot(
            themePreference: theme,
            readingTextScale: scale
        )
    }

    public func setThemePreference(_ preference: AppThemePreference) async {
        defaults.set(preference.rawValue, forKey: Self.themePreferenceKey)
    }

    public func setReadingTextScale(_ value: Double) async {
        defaults.set(AppSettingsSnapshot.snapReadingTextScale(value), forKey: Self.readingTextScaleKey)
    }
}
