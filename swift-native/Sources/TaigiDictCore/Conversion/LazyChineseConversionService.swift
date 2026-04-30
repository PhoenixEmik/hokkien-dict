import Foundation

public actor LazyChineseConversionService: ChineseConversionProviding {
    private var service: ChineseConversionService?

    public init() {}

    public func normalizeSearchInput(_ text: String, locale: AppLocale) async -> String {
        guard shouldLoadConverter(for: text, locale: locale),
              let service = resolveService() else {
            return text
        }

        return await service.normalizeSearchInput(text, locale: locale)
    }

    public func translateForDisplay(_ text: String, locale: AppLocale) async -> String {
        guard shouldLoadConverter(for: text, locale: locale),
              let service = resolveService() else {
            return text
        }

        return await service.translateForDisplay(text, locale: locale)
    }

    private func resolveService() -> ChineseConversionService? {
        if let service {
            return service
        }

        guard let service = try? ChineseConversionService() else {
            return nil
        }

        self.service = service
        return service
    }

    private func shouldLoadConverter(for text: String, locale: AppLocale) -> Bool {
        locale.usesSimplifiedChineseDisplay && OpenCCInputGuard.shouldConvert(text)
    }
}
