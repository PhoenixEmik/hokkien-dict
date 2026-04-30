import SwiftUI
import TaigiDictCore

struct LicenseSummaryScreen: View {
    private let ministryCopyrightURL = URL(string: "https://sutian.moe.edu.tw/zh-hant/piantsip/pankhuan-singbing/")!

    @Environment(\.locale) private var locale

    private var appLocale: AppLocale {
        AppLocalizer.appLocale(from: locale)
    }

    var body: some View {
        List {
            Section {
                LicenseStaticRow(
                    systemImage: "chevron.left.forwardslash.chevron.right",
                    title: AppLocalizer.text(.licenseAppCode, locale: appLocale),
                    subtitle: AppLocalizer.text(.licenseAppCodeDescription, locale: appLocale)
                )

                LicenseStaticRow(
                    systemImage: "book.closed",
                    title: AppLocalizer.text(.licenseData, locale: appLocale),
                    subtitle: AppLocalizer.text(.licenseDataDescription, locale: appLocale)
                )

                LicenseStaticRow(
                    systemImage: "speaker.wave.2",
                    title: AppLocalizer.text(.licenseAudio, locale: appLocale),
                    subtitle: AppLocalizer.text(.licenseAudioDescription, locale: appLocale)
                )

                LicenseExternalLinkRow(
                    systemImage: "c.circle",
                    title: AppLocalizer.text(.licenseMinistryCopyright, locale: appLocale),
                    subtitle: ministryCopyrightURL.absoluteString,
                    destination: ministryCopyrightURL
                )
            }

            Section {
                NavigationLink {
                    LicenseOverviewScreen()
                } label: {
                    LicenseNavigationRow(
                        systemImage: "swift",
                        title: AppLocalizer.text(.licenseThirdParty, locale: appLocale),
                        subtitle: AppLocalizer.text(.licenseViewThirdParty, locale: appLocale)
                    )
                }
            }
        }
        .navigationTitle(AppLocalizer.text(.licenseTitle, locale: appLocale))
    }
}

private struct LicenseStaticRow: View {
    let systemImage: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            SettingsIconBadge(systemImage: systemImage)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct LicenseExternalLinkRow: View {
    let systemImage: String
    let title: String
    let subtitle: String
    let destination: URL

    var body: some View {
        Link(destination: destination) {
            HStack(alignment: .top, spacing: 12) {
                SettingsIconBadge(systemImage: systemImage)
                    .padding(.top, 1)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .textSelection(.enabled)
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

private struct LicenseNavigationRow: View {
    let systemImage: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            SettingsIconBadge(systemImage: systemImage)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(.vertical, 4)
    }
}
