import Foundation
import OpenCC

public actor ChineseConversionService: ChineseConversionProviding {
    private let searchInputConverter: ChineseConverter
    private let simplifiedDisplayConverter: ChineseConverter

    public init() throws {
        searchInputConverter = try ChineseConverter(options: [.traditionalize, .twStandard, .twIdiom])
        simplifiedDisplayConverter = try ChineseConverter(options: [.simplify])
    }

    public func normalizeSearchInput(_ text: String, locale: AppLocale) async -> String {
        guard locale.usesSimplifiedChineseDisplay, OpenCCInputGuard.shouldConvert(text) else {
            return text
        }

        return searchInputConverter.convert(text)
    }

    public func translateForDisplay(_ text: String, locale: AppLocale) async -> String {
        guard locale.usesSimplifiedChineseDisplay, OpenCCInputGuard.shouldConvert(text) else {
            return text
        }

        return simplifiedDisplayConverter.convert(text)
    }
}
