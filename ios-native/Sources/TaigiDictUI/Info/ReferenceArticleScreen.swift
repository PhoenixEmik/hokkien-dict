import SwiftUI
import TaigiDictCore

struct ReferenceArticleSectionModel {
    let title: String
    let paragraphs: [String]
    let bullets: [String]
    let tableRows: [(String, String)]
}

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
                    sections: [
                        ReferenceArticleSectionModel(
                            title: AppLocalizer.text(.referenceTaiLoSectionGeneralTones, locale: appLocale),
                            paragraphs: [
                                AppLocalizer.text(.referenceTaiLoP1, locale: appLocale),
                            ],
                            bullets: [
                                AppLocalizer.text(.referenceTaiLoB1, locale: appLocale),
                                AppLocalizer.text(.referenceTaiLoB2, locale: appLocale),
                            ],
                            tableRows: [
                                ("1 / 2 / 3 / 4", AppLocalizer.text(.referenceTaiLoToneRow1Value, locale: appLocale)),
                                ("5 / 7 / 8", AppLocalizer.text(.referenceTaiLoToneRow2Value, locale: appLocale)),
                            ]
                        ),
                        ReferenceArticleSectionModel(
                            title: AppLocalizer.text(.referenceTaiLoSectionSpecialTones, locale: appLocale),
                            paragraphs: [
                                AppLocalizer.text(.referenceTaiLoP2, locale: appLocale),
                            ],
                            bullets: [
                                AppLocalizer.text(.referenceTaiLoB3, locale: appLocale),
                                AppLocalizer.text(.referenceTaiLoB4, locale: appLocale),
                            ],
                            tableRows: []
                        ),
                        ReferenceArticleSectionModel(
                            title: AppLocalizer.text(.referenceTaiLoSectionToneSandhi, locale: appLocale),
                            paragraphs: [
                                AppLocalizer.text(.referenceTaiLoB5, locale: appLocale),
                            ],
                            bullets: [
                                AppLocalizer.text(.referenceTaiLoB6, locale: appLocale),
                            ],
                            tableRows: [
                                ("1 → 7", AppLocalizer.text(.referenceTaiLoSandhiRow1Value, locale: appLocale)),
                                ("2 → 1", AppLocalizer.text(.referenceTaiLoSandhiRow2Value, locale: appLocale)),
                                ("3 → 2", AppLocalizer.text(.referenceTaiLoSandhiRow3Value, locale: appLocale)),
                                ("7 → 3", AppLocalizer.text(.referenceTaiLoSandhiRow4Value, locale: appLocale)),
                            ]
                        ),
                        ReferenceArticleSectionModel(
                            title: AppLocalizer.text(.referenceTaiLoSectionNeutralTone, locale: appLocale),
                            paragraphs: [
                                AppLocalizer.text(.referenceTaiLoB5, locale: appLocale),
                            ],
                            bullets: [
                                AppLocalizer.text(.referenceTaiLoNeutralExample1, locale: appLocale),
                                AppLocalizer.text(.referenceTaiLoNeutralExample2, locale: appLocale),
                                AppLocalizer.text(.referenceTaiLoNeutralExample3, locale: appLocale),
                            ],
                            tableRows: []
                        ),
                    ]
                )
            } label: {
                Label(AppLocalizer.text(.referenceTaiLoTitle, locale: appLocale), systemImage: "text.book.closed")
            }

            NavigationLink {
                ReferenceArticleScreen(
                    title: AppLocalizer.text(.referenceHanjiTitle, locale: appLocale),
                    sections: [
                        ReferenceArticleSectionModel(
                            title: AppLocalizer.text(.referenceHanjiSectionOverview, locale: appLocale),
                            paragraphs: [
                                AppLocalizer.text(.referenceHanjiP1, locale: appLocale),
                            ],
                            bullets: [
                                AppLocalizer.text(.referenceHanjiB1, locale: appLocale),
                            ],
                            tableRows: []
                        ),
                        ReferenceArticleSectionModel(
                            title: AppLocalizer.text(.referenceHanjiSectionTypes, locale: appLocale),
                            paragraphs: [
                                AppLocalizer.text(.referenceHanjiP2, locale: appLocale),
                            ],
                            bullets: [
                                AppLocalizer.text(.referenceHanjiB2, locale: appLocale),
                                AppLocalizer.text(.referenceHanjiB3, locale: appLocale),
                                AppLocalizer.text(.referenceHanjiB4, locale: appLocale),
                            ],
                            tableRows: []
                        ),
                        ReferenceArticleSectionModel(
                            title: AppLocalizer.text(.referenceHanjiSectionSubstitute, locale: appLocale),
                            paragraphs: [],
                            bullets: [
                                AppLocalizer.text(.referenceHanjiB5, locale: appLocale),
                            ],
                            tableRows: [
                                ("塍 → 田", AppLocalizer.text(.referenceHanjiSubstituteRow1Value, locale: appLocale)),
                                ("農／儂 → 人", AppLocalizer.text(.referenceHanjiSubstituteRow2Value, locale: appLocale)),
                                ("治 → 刣", AppLocalizer.text(.referenceHanjiSubstituteRow3Value, locale: appLocale)),
                            ]
                        ),
                        ReferenceArticleSectionModel(
                            title: AppLocalizer.text(.referenceHanjiSectionRecommended, locale: appLocale),
                            paragraphs: [
                                AppLocalizer.text(.referenceHanjiRecommendedP1, locale: appLocale)
                            ],
                            bullets: [],
                            tableRows: []
                        ),
                    ]
                )
            } label: {
                Label(AppLocalizer.text(.referenceHanjiTitle, locale: appLocale), systemImage: "character.textbox")
            }
        }
        .navigationTitle(AppLocalizer.text(.referenceTitle, locale: appLocale))
    }
}

struct ReferenceArticleScreen: View {
    @Environment(\.locale) private var locale
    var title: String
    var sections: [ReferenceArticleSectionModel]

    var body: some View {
        List {
            ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                if !section.paragraphs.isEmpty {
                    Section(section.title) {
                        ForEach(section.paragraphs, id: \.self) { paragraph in
                            Text(paragraph)
                        }
                    }
                }

                if !section.bullets.isEmpty {
                    Section {
                        ForEach(section.bullets, id: \.self) { bullet in
                            Label(bullet, systemImage: "circle.fill")
                                .symbolRenderingMode(.monochrome)
                                .font(.body)
                        }
                    }
                }

                if !section.tableRows.isEmpty {
                    Section {
                        ForEach(Array(section.tableRows.enumerated()), id: \.offset) { _, row in
                            LabeledContent(row.0) {
                                Text(row.1)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(title)
    }
}
