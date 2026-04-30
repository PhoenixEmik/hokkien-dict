import XCTest
@testable import TaigiDictCore

final class LazyChineseConversionServiceTests: XCTestCase {
    func testTraditionalLocaleReturnsOriginalTextWithoutRequiringConversion() async {
        let service = LazyChineseConversionService()

        let normalized = await service.normalizeSearchInput("辞典", locale: .traditionalChinese)
        let displayed = await service.translateForDisplay("辭典", locale: .traditionalChinese)

        XCTAssertEqual(normalized, "辞典")
        XCTAssertEqual(displayed, "辭典")
    }

    func testRomanizationReturnsOriginalTextWithoutRequiringConversion() async {
        let service = LazyChineseConversionService()

        let normalized = await service.normalizeSearchInput("sû-tián", locale: .simplifiedChinese)
        let displayed = await service.translateForDisplay("sû-tián", locale: .simplifiedChinese)

        XCTAssertEqual(normalized, "sû-tián")
        XCTAssertEqual(displayed, "sû-tián")
    }
}
