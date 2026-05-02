import Foundation
import TaigiDictCore

public enum AppLanguage: String, CaseIterable, Codable, Hashable, Sendable {
    case system = "system"
    case zhHant = "zh-Hant"
    case zhHans = "zh-Hans"
    case en = "en"

    var localizationIdentifier: String? {
        switch self {
        case .system:
            return nil
        case .zhHant:
            return Self.zhHant.rawValue
        case .zhHans:
            return Self.zhHans.rawValue
        case .en:
            return Self.en.rawValue
        }
    }

    func resolvedLocale(systemLocale: Locale) -> Locale {
        switch self {
        case .system:
            return systemLocale
        case .zhHant:
            return Locale(identifier: Self.zhHant.rawValue)
        case .zhHans:
            return Locale(identifier: Self.zhHans.rawValue)
        case .en:
            return Locale(identifier: Self.en.rawValue)
        }
    }

    func resolvedAppLocale(systemLocale: Locale) -> AppLocale {
        AppLocalizer.appLocale(from: resolvedLocale(systemLocale: systemLocale))
    }
}