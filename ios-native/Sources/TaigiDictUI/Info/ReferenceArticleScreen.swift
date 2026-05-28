import SwiftUI
import TaigiDictCore

private struct ReferenceArticleRowModel: Decodable {
    let label: String
    let value: String
}

private struct ReferenceArticleSectionModel: Decodable {
    let title: String
    let paragraphs: [String]
    let orderedItems: [String]
    let bullets: [String]
    let tableRows: [ReferenceArticleRowModel]
}

private struct ReferenceArticleDocument: Decodable {
    let title: String
    let sections: [ReferenceArticleSectionModel]
}

enum ReferenceArticleKind: String {
    case taiLo = "reference_tailo"
    case hanji = "reference_hanji"
}

private enum ReferenceArticleRepository {
    static func load(kind: ReferenceArticleKind, locale: AppLocale) throws -> ReferenceArticleDocument {
        let localeCode = switch locale {
        case .traditionalChinese:
            "zh-Hant"
        case .simplifiedChinese:
            "zh-Hans"
        case .english:
            "en"
        }

        let resourceName = "\(kind.rawValue)_\(localeCode)"
        let url = Bundle.module.url(
            forResource: resourceName,
            withExtension: "json",
            subdirectory: "ReferenceArticles"
        ) ?? Bundle.module.url(
            forResource: resourceName,
            withExtension: "json"
        )

        guard let url else {
            throw CocoaError(.fileNoSuchFile)
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(ReferenceArticleDocument.self, from: data)
    }
}

struct ReferenceArticleListScreen: View {
    @Environment(\.locale) private var locale

    private var appLocale: AppLocale {
        AppLocalizer.appLocale(from: locale)
    }

    var body: some View {
        List {
            NavigationLink {
                LocalizedReferenceArticleScreen(
                    kind: .taiLo,
                    fallbackTitle: AppLocalizer.text(.referenceTaiLoTitle, locale: appLocale)
                )
            } label: {
                Label(AppLocalizer.text(.referenceTaiLoTitle, locale: appLocale), systemImage: "text.book.closed")
            }

            NavigationLink {
                LocalizedReferenceArticleScreen(
                    kind: .hanji,
                    fallbackTitle: AppLocalizer.text(.referenceHanjiTitle, locale: appLocale)
                )
            } label: {
                Label(AppLocalizer.text(.referenceHanjiTitle, locale: appLocale), systemImage: "character.textbox")
            }
        }
        .navigationTitle(AppLocalizer.text(.referenceTitle, locale: appLocale))
    }
}

struct LocalizedReferenceArticleScreen: View {
    @Environment(\.locale) private var locale
    let kind: ReferenceArticleKind
    let fallbackTitle: String

    private var appLocale: AppLocale {
        AppLocalizer.appLocale(from: locale)
    }

    private var articleResult: Result<ReferenceArticleDocument, Error> {
        Result {
            try ReferenceArticleRepository.load(kind: kind, locale: appLocale)
        }
    }

    var body: some View {
        switch articleResult {
        case .success(let article):
            ReferenceArticleScreen(title: article.title, sections: article.sections)
        case .failure(let error):
            List {
                ContentUnavailableView(
                    AppLocalizer.text(.loadingFailedTitle, locale: appLocale),
                    systemImage: "exclamationmark.triangle",
                    description: Text(error.localizedDescription)
                )
            }
            .navigationTitle(fallbackTitle)
        }
    }
}

private struct ReferenceArticleScreen: View {
    let title: String
    let sections: [ReferenceArticleSectionModel]

    var body: some View {
        List {
            ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                Section(section.title) {
                    ForEach(section.paragraphs, id: \.self) { paragraph in
                        Text(paragraph)
                    }

                    ForEach(Array(section.orderedItems.enumerated()), id: \.offset) { index, item in
                        ReferenceArticleOrderedRow(number: index + 1, text: item)
                    }

                    ForEach(section.bullets, id: \.self) { bullet in
                        ReferenceArticleBulletRow(text: bullet)
                    }

                    ForEach(Array(section.tableRows.enumerated()), id: \.offset) { _, row in
                        LabeledContent(row.label) {
                            Text(row.value)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                }
            }
        }
        .navigationTitle(title)
        .textSelection(.enabled)
    }
}

private struct ReferenceArticleOrderedRow: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\(number).")
                .foregroundStyle(.secondary)
            Text(text)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct ReferenceArticleBulletRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "circle.fill")
                .font(.system(size: 5))
                .padding(.top, 8)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text(text)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
