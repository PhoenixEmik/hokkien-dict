import Foundation

public protocol ChineseConversionProviding: Sendable {
    func normalizeSearchInput(_ text: String, locale: AppLocale) async -> String
    func translateForDisplay(_ text: String, locale: AppLocale) async -> String
}
