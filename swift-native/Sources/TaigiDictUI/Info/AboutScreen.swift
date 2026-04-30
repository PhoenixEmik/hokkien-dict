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
        aboutList
            .navigationTitle(AppLocalizer.text(.aboutTitle, locale: appLocale))
    }

    @ViewBuilder
    private var aboutList: some View {
        #if os(iOS)
        List {
            Section(AppLocalizer.text(.aboutAppSection, locale: appLocale)) {
                AboutValueRow(
                    title: AppLocalizer.text(.aboutVersion, locale: appLocale),
                    value: appVersion,
                    systemImage: "number.circle"
                )

                AboutValueRow(
                    title: AppLocalizer.text(.aboutAuthor, locale: appLocale),
                    value: "PhoenixEmik",
                    systemImage: "person.crop.circle"
                )

                AboutExternalLinkRow(
                    title: AppLocalizer.text(.aboutGitHub, locale: appLocale),
                    systemImage: "chevron.left.forwardslash.chevron.right",
                    destination: repositoryURL
                )
            }

            Section(AppLocalizer.text(.aboutProjectSection, locale: appLocale)) {
                NavigationLink {
                    LicenseSummaryScreen()
                } label: {
                    AboutNavigationRow(
                        title: AppLocalizer.text(.settingsLicenses, locale: appLocale),
                        systemImage: "doc.text"
                    )
                }

                AboutExternalLinkRow(
                    title: AppLocalizer.text(.aboutPrivacy, locale: appLocale),
                    systemImage: "hand.raised",
                    destination: privacyURL
                )
            }

            Section(AppLocalizer.text(.referenceTitle, locale: appLocale)) {
                AboutExternalLinkRow(
                    title: AppLocalizer.text(.aboutReferencePage, locale: appLocale),
                    systemImage: "books.vertical",
                    destination: referencePageURL
                )

                AboutExternalLinkRow(
                    title: AppLocalizer.text(.referenceTaiLoTitle, locale: appLocale),
                    systemImage: "textformat.abc",
                    destination: taiLoGuideURL
                )

                AboutExternalLinkRow(
                    title: AppLocalizer.text(.referenceHanjiTitle, locale: appLocale),
                    systemImage: "character.book.closed",
                    destination: hanjiGuideURL
                )
            }
        }
        .listStyle(.insetGrouped)
        #else
        List {
            Section(AppLocalizer.text(.aboutAppSection, locale: appLocale)) {
                AboutValueRow(
                    title: AppLocalizer.text(.aboutVersion, locale: appLocale),
                    value: appVersion,
                    systemImage: "number.circle"
                )

                AboutValueRow(
                    title: AppLocalizer.text(.aboutAuthor, locale: appLocale),
                    value: "PhoenixEmik",
                    systemImage: "person.crop.circle"
                )

                AboutExternalLinkRow(
                    title: AppLocalizer.text(.aboutGitHub, locale: appLocale),
                    systemImage: "chevron.left.forwardslash.chevron.right",
                    destination: repositoryURL
                )
            }

            Section(AppLocalizer.text(.aboutProjectSection, locale: appLocale)) {
                NavigationLink {
                    LicenseSummaryScreen()
                } label: {
                    AboutNavigationRow(
                        title: AppLocalizer.text(.settingsLicenses, locale: appLocale),
                        systemImage: "doc.text"
                    )
                }

                AboutExternalLinkRow(
                    title: AppLocalizer.text(.aboutPrivacy, locale: appLocale),
                    systemImage: "hand.raised",
                    destination: privacyURL
                )
            }

            Section(AppLocalizer.text(.referenceTitle, locale: appLocale)) {
                AboutExternalLinkRow(
                    title: AppLocalizer.text(.aboutReferencePage, locale: appLocale),
                    systemImage: "books.vertical",
                    destination: referencePageURL
                )

                AboutExternalLinkRow(
                    title: AppLocalizer.text(.referenceTaiLoTitle, locale: appLocale),
                    systemImage: "textformat.abc",
                    destination: taiLoGuideURL
                )

                AboutExternalLinkRow(
                    title: AppLocalizer.text(.referenceHanjiTitle, locale: appLocale),
                    systemImage: "character.book.closed",
                    destination: hanjiGuideURL
                )
            }
        }
        #endif
    }

    private var appVersion: String {
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
           !version.isEmpty {
            return version
        }

        return AppLocalizer.text(.aboutVersionValue, locale: appLocale)
    }
}

private struct AboutValueRow: View {
    let title: String
    let value: String
    let systemImage: String

    var body: some View {
        LabeledContent {
            Text(value)
                .foregroundStyle(.secondary)
        } label: {
            HStack(spacing: 12) {
                SettingsIconBadge(systemImage: systemImage)
                Text(title)
            }
        }
    }
}

private struct AboutExternalLinkRow: View {
    let title: String
    let systemImage: String
    let destination: URL

    var body: some View {
        Link(destination: destination) {
            HStack {
                HStack(spacing: 12) {
                    SettingsIconBadge(systemImage: systemImage)
                    Text(title)
                }
                .foregroundStyle(.primary)

                Spacer(minLength: 12)

                Image(systemName: "arrow.up.right.square")
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

private struct AboutNavigationRow: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            SettingsIconBadge(systemImage: systemImage)
            Text(title)
        }
            .padding(.vertical, 4)
    }
}
