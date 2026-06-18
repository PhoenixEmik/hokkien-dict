import XCTest
import TaigiDictCore
@testable import TaigiDictUI

final class ReferenceArticleRepositoryTests: XCTestCase {
    func testLoadsEnglishReferenceArticles() throws {
        try assertArticle(
            kind: .taiLo,
            locale: .english,
            expectedTitle: "Taiwanese Hokkien Romanization Scheme"
        )
        try assertArticle(
            kind: .hanji,
            locale: .english,
            expectedTitle: "Hanzi Character Usage Principles"
        )
    }

    func testLoadsJapaneseReferenceArticles() throws {
        try assertArticle(
            kind: .taiLo,
            locale: .japanese,
            expectedTitle: "台湾語ローマ字表記法"
        )
        try assertArticle(
            kind: .hanji,
            locale: .japanese,
            expectedTitle: "漢字表記の原則"
        )
    }

    private func assertArticle(
        kind: ReferenceArticleKind,
        locale: AppLocale,
        expectedTitle: String
    ) throws {
        let article = try ReferenceArticleRepository.load(kind: kind, locale: locale)

        XCTAssertEqual(article.title, expectedTitle)
        XCTAssertFalse(article.sections.isEmpty)
    }
}
