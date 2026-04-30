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
            Section {
                AboutSummaryRow(
                    title: AppLocalizer.text(.aboutAppSection, locale: appLocale),
                    description: AppLocalizer.text(.aboutAppDescription, locale: appLocale)
                )

                LabeledContent(AppLocalizer.text(.aboutVersion, locale: appLocale)) {
                    Text(appVersion)
                }

                LabeledContent(AppLocalizer.text(.aboutAuthor, locale: appLocale)) {
                    Text("PhoenixEmik")
                }

                AboutExternalLinkRow(
                    title: AppLocalizer.text(.aboutGitHub, locale: appLocale),
                    subtitle: repositoryURL.absoluteString,
                    destination: repositoryURL
                )
            }

            Section {
                NavigationLink {
                    LicenseSummaryScreen()
                } label: {
                    AboutNavigationRow(
                        title: AppLocalizer.text(.settingsLicenses, locale: appLocale),
                        subtitle: AppLocalizer.text(.aboutLicensesSubtitle, locale: appLocale)
                    )
                }

                AboutExternalLinkRow(
                    title: AppLocalizer.text(.aboutPrivacy, locale: appLocale),
                    subtitle: AppLocalizer.text(.aboutPrivacySubtitle, locale: appLocale),
                    destination: privacyURL
                )
            }

            Section(AppLocalizer.text(.referenceTitle, locale: appLocale)) {
                AboutExternalLinkRow(
                    title: AppLocalizer.text(.aboutReferencePage, locale: appLocale),
                    subtitle: referencePageURL.absoluteString,
                    destination: referencePageURL
                )

                AboutExternalLinkRow(
                    title: AppLocalizer.text(.referenceTaiLoTitle, locale: appLocale),
                    subtitle: taiLoGuideURL.absoluteString,
                    destination: taiLoGuideURL
                )

                AboutExternalLinkRow(
                    title: AppLocalizer.text(.referenceHanjiTitle, locale: appLocale),
                    subtitle: hanjiGuideURL.absoluteString,
                    destination: hanjiGuideURL
                )
            }
        }
        .navigationTitle(AppLocalizer.text(.aboutTitle, locale: appLocale))
    }

    private var appVersion: String {
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
           !version.isEmpty {
            return version
        }

        return AppLocalizer.text(.aboutVersionValue, locale: appLocale)
    }
}

private struct AboutSummaryRow: View {
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle")
                .foregroundStyle(.secondary)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct AboutExternalLinkRow: View {
    let title: String
    let subtitle: String
    let destination: URL

    var body: some View {
        Link(destination: destination) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 12)

                Image(systemName: "arrow.up.right.square")
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

private struct AboutNavigationRow: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
