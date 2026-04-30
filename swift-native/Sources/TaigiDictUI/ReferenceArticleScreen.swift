import SwiftUI
import TaigiDictCore

struct ReferenceArticleListScreen: View {
    @Environment(\.locale) private var locale

    private var appLocale: AppLocale {
        AppLocalizer.appLocale(from: locale)
    }

    var body: some View {
        List {
            NavigationLink {
                ReferenceArticleScreen(
                    title: AppLocalizer.text(.referenceTaiLoTitle, locale: appLocale),
                    paragraphs: [
                        AppLocalizer.text(.referenceTaiLoP1, locale: appLocale),
                        AppLocalizer.text(.referenceTaiLoP2, locale: appLocale),
                    ],
                    bullets: [
                        AppLocalizer.text(.referenceTaiLoB1, locale: appLocale),
                        AppLocalizer.text(.referenceTaiLoB2, locale: appLocale),
                        AppLocalizer.text(.referenceTaiLoB3, locale: appLocale),
                    ],
                    tableRows: [
                        ("oo", "o-dot-right"),
                        ("nn", "superscript-n"),
                    ]
                )
            } label: {
                Label(AppLocalizer.text(.referenceTaiLoTitle, locale: appLocale), systemImage: "character.book.closed")
            }

            NavigationLink {
                ReferenceArticleScreen(
                    title: AppLocalizer.text(.referenceHanjiTitle, locale: appLocale),
                    paragraphs: [
                        AppLocalizer.text(.referenceHanjiP1, locale: appLocale),
                        AppLocalizer.text(.referenceHanjiP2, locale: appLocale),
                    ],
                    bullets: [
                        AppLocalizer.text(.referenceHanjiB1, locale: appLocale),
                        AppLocalizer.text(.referenceHanjiB2, locale: appLocale),
                    ],
                    tableRows: []
                )
            } label: {
                Label(AppLocalizer.text(.referenceHanjiTitle, locale: appLocale), systemImage: "textformat.abc")
            }
        }
        .navigationTitle(AppLocalizer.text(.referenceTitle, locale: appLocale))
    }
}

struct ReferenceArticleScreen: View {
    @Environment(\.locale) private var locale
    var title: String
    var paragraphs: [String]
    var bullets: [String]
    var tableRows: [(String, String)]

    var body: some View {
        let appLocale = AppLocalizer.appLocale(from: locale)
        List {
            if !paragraphs.isEmpty {
                Section(AppLocalizer.text(.referenceContentSection, locale: appLocale)) {
                    ForEach(paragraphs, id: \.self) { paragraph in
                        Text(paragraph)
                    }
                }
            }

            if !bullets.isEmpty {
                Section(AppLocalizer.text(.referenceKeyPointsSection, locale: appLocale)) {
                    ForEach(bullets, id: \.self) { bullet in
                        Label(bullet, systemImage: "circle.fill")
                            .symbolRenderingMode(.monochrome)
                            .font(.body)
                    }
                }
            }

            if !tableRows.isEmpty {
                Section(AppLocalizer.text(.referenceMappingSection, locale: appLocale)) {
                    ForEach(Array(tableRows.enumerated()), id: \.offset) { _, row in
                        LabeledContent(row.0) {
                            Text(row.1)
                        }
                    }
                }
            }
        }
        .navigationTitle(title)
    }
}
