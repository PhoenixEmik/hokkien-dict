import Combine
import Foundation
import TaigiDictCore

public final class AppLanguageManager: ObservableObject {
    public static let userDefaultsKey = "app_language"
    static let uiTestLanguageKey = "UITEST_APP_LANGUAGE"

    @Published public private(set) var selectedLanguage: AppLanguage
    @Published private var systemLocaleIdentifier: String

    private let defaults: UserDefaults

    public init(
        defaults: UserDefaults = .standard,
        systemLocale: Locale = .autoupdatingCurrent,
        processInfo: ProcessInfo = .processInfo
    ) {
        self.defaults = defaults
        let overriddenLanguage = processInfo.environment[Self.uiTestLanguageKey].flatMap(AppLanguage.init(rawValue:))
        selectedLanguage = overriddenLanguage
            ?? AppLanguage(rawValue: defaults.string(forKey: Self.userDefaultsKey) ?? "")
            ?? .system
        systemLocaleIdentifier = systemLocale.identifier
        AppLocalizer.configure(language: selectedLanguage, systemLocale: systemLocale)
    }

    public var systemLocale: Locale {
        Locale(identifier: systemLocaleIdentifier)
    }

    public var locale: Locale {
        selectedLanguage.resolvedLocale(systemLocale: systemLocale)
    }

    public var appLocale: AppLocale {
        selectedLanguage.resolvedAppLocale(systemLocale: systemLocale)
    }

    public func updateSystemLocale(_ locale: Locale) {
        guard systemLocaleIdentifier != locale.identifier else {
            return
        }

        systemLocaleIdentifier = locale.identifier
        AppLocalizer.configure(language: selectedLanguage, systemLocale: locale)
    }

    public func setLanguage(_ language: AppLanguage) {
        guard selectedLanguage != language else {
            return
        }

        selectedLanguage = language
        defaults.set(language.rawValue, forKey: Self.userDefaultsKey)
        AppLocalizer.configure(language: language, systemLocale: systemLocale)
    }

    public func localized(_ key: AppLocalizedStringKey) -> String {
        AppLocalizer.text(key, language: selectedLanguage, systemLocale: systemLocale)
    }

    public func formattedLocalized(_ key: AppLocalizedStringKey, _ arguments: CVarArg...) -> String {
        AppLocalizer.formattedText(
            key,
            language: selectedLanguage,
            systemLocale: systemLocale,
            arguments: arguments
        )
    }

    public func displayName(for language: AppLanguage) -> String {
        localized(language.localizedStringKey)
    }
}

private extension AppLanguage {
    var localizedStringKey: AppLocalizedStringKey {
        switch self {
        case .system:
            return .localeSystem
        case .zhHant:
            return .localeTraditionalChinese
        case .zhHans:
            return .localeSimplifiedChinese
        case .en:
            return .localeEnglish
        }
    }
}