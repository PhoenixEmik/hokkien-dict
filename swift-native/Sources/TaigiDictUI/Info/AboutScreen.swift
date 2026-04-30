import SwiftUI
import TaigiDictCore

struct AboutScreen: View {
    private let repositoryURL = URL(string: "https://github.com/PhoenixEmik/taigi-dict")!
    private let privacyURL = URL(string: "https://github.com/PhoenixEmik/taigi-dict/blob/main/PRIVACY_POLICY.md")!
    private let referencePageURL = URL(string: "https://sutian.moe.edu.tw/zh-hant/siongkuantsuguan/")!
    private let taiLoGuideURL = URL(string: "https://sutian.moe.edu.tw/zh-hant/piantsip/tailo-phiautsu-suatbing/")!
    private let hanjiGuideURL = URL(string: "https://sutian.moe.edu.tw/zh-hant/piantsip/hanji-iongji-guantsik/")!

    @Environment(\.locale) private var locale

    private var appLocale: AppLocale {
        AppLocalizer.appLocale(from: locale)
    }

    var body: some View {
        List {
            aboutSections
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #endif
            .navigationTitle(AppLocalizer.text(.aboutTitle, locale: appLocale))
    }

    @ViewBuilder
    private var aboutSections: some View {
        Section(AppLocalizer.text(.aboutAppSection, locale: appLocale)) {
            LabeledContent {
                Text(appVersion)
                    .foregroundStyle(.secondary)
            } label: {
                Label(AppLocalizer.text(.aboutVersion, locale: appLocale), systemImage: "number.circle")
            }

            LabeledContent {
                Text("PhoenixEmik")
                    .foregroundStyle(.secondary)
            } label: {
                Label(AppLocalizer.text(.aboutAuthor, locale: appLocale), systemImage: "person.crop.circle")
            }

            Link(destination: repositoryURL) {
                Label(AppLocalizer.text(.aboutGitHub, locale: appLocale), systemImage: "chevron.left.forwardslash.chevron.right")
            }
        }

        Section(AppLocalizer.text(.aboutProjectSection, locale: appLocale)) {
            NavigationLink {
                LicenseSummaryScreen()
            } label: {
                Label(AppLocalizer.text(.settingsLicenses, locale: appLocale), systemImage: "doc.text")
            }

            Link(destination: privacyURL) {
                Label(AppLocalizer.text(.aboutPrivacy, locale: appLocale), systemImage: "hand.raised")
            }
        }

        Section(AppLocalizer.text(.referenceTitle, locale: appLocale)) {
            Link(destination: referencePageURL) {
                Label(AppLocalizer.text(.aboutReferencePage, locale: appLocale), systemImage: "books.vertical")
            }

            Link(destination: taiLoGuideURL) {
                Label(AppLocalizer.text(.referenceTaiLoTitle, locale: appLocale), systemImage: "text.book.closed")
            }

            Link(destination: hanjiGuideURL) {
                Label(AppLocalizer.text(.referenceHanjiTitle, locale: appLocale), systemImage: "character.textbox")
            }
        }
    }

    private var appVersion: String {
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
           !version.isEmpty {
            return version
        }

        return AppLocalizer.text(.aboutVersionValue, locale: appLocale)
    }
}
