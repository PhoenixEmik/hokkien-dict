import SwiftUI
import TaigiDictCore

struct ReferenceArticleRowModel: Decodable {
    let label: String
    let value: String
}

struct ReferenceArticleSectionModel: Decodable {
    let title: String
    let paragraphs: [String]
    let orderedItems: [String]
    let bullets: [String]
    let tableRows: [ReferenceArticleRowModel]
}

struct ReferenceArticleDocument: Decodable {
    let title: String
    let sections: [ReferenceArticleSectionModel]
}

public enum ReferenceArticleViewerWindow {
    public static let windowID = "reference-viewer"
}

enum ReferenceArticleKind: String, CaseIterable {
    case taiLo = "reference_tailo"
    case hanji = "reference_hanji"
}

private extension ReferenceArticleKind {
    var systemImage: String {
        switch self {
        case .taiLo:
            "text.book.closed"
        case .hanji:
            "character.textbox"
        }
    }

    func displayTitle(locale: AppLocale) -> String {
        switch self {
        case .taiLo:
            AppLocalizer.text(.referenceTaiLoTitle, locale: locale)
        case .hanji:
            AppLocalizer.text(.referenceHanjiTitle, locale: locale)
        }
    }
}

enum ReferenceArticleRepository {
    static func load(kind: ReferenceArticleKind, locale: AppLocale) throws -> ReferenceArticleDocument {
        let localeCode = switch locale {
        case .traditionalChinese:
            "zh-Hant"
        case .simplifiedChinese:
            "zh-Hans"
        case .english:
            "en"
        case .japanese:
            "ja"
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

public struct ReferenceArticleListScreen: View {
    @Environment(\.locale) private var locale

    private var appLocale: AppLocale {
        AppLocalizer.appLocale(from: locale)
    }

    public init() {}

    public var body: some View {
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

#if os(macOS)
public struct MacReferenceArticleViewer: View {
    @Environment(\.locale) private var locale
    @State private var selectedKind: ReferenceArticleKind? = .taiLo

    private var appLocale: AppLocale {
        AppLocalizer.appLocale(from: locale)
    }

    public init() {}

    public var body: some View {
        NavigationSplitView {
            List(ReferenceArticleKind.allCases, id: \.self, selection: $selectedKind) { kind in
                Label(kind.displayTitle(locale: appLocale), systemImage: kind.systemImage)
                    .tag(kind)
            }
            .listStyle(.sidebar)
            .navigationTitle(AppLocalizer.text(.referenceTitle, locale: appLocale))
        } detail: {
            if let selectedKind {
                LocalizedReferenceArticleReaderView(
                    kind: selectedKind,
                    fallbackTitle: selectedKind.displayTitle(locale: appLocale)
                )
            } else {
                ContentUnavailableView(
                    AppLocalizer.text(.referenceTitle, locale: appLocale),
                    systemImage: "text.book.closed",
                    description: Text(AppLocalizer.text(.referenceViewerDescription, locale: appLocale))
                )
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}
#endif

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

private struct LocalizedReferenceArticleReaderView: View {
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
            ReferenceArticleReaderScreen(title: article.title, sections: article.sections)
        case .failure(let error):
            ContentUnavailableView(
                AppLocalizer.text(.loadingFailedTitle, locale: appLocale),
                systemImage: "exclamationmark.triangle",
                description: Text(error.localizedDescription)
            )
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

private struct ReferenceArticleReaderScreen: View {
    let title: String
    let sections: [ReferenceArticleSectionModel]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                Text(title)
                    .font(.largeTitle.weight(.semibold))

                ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                    VStack(alignment: .leading, spacing: 14) {
                        Text(section.title)
                            .font(.title3.weight(.semibold))

                        ForEach(section.paragraphs, id: \.self) { paragraph in
                            Text(paragraph)
                                .frame(maxWidth: .infinity, alignment: .leading)
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
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.trailing)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .font(.body)
            .lineSpacing(4)
            .textSelection(.enabled)
            .frame(maxWidth: 700, alignment: .leading)
            .padding(.horizontal, 36)
            .padding(.vertical, 28)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(title)
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
