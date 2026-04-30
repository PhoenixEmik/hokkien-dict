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
                LabeledContent {
                    Text(AppLocalizer.text(.licenseAppCodeDescription, locale: appLocale))
                        .foregroundStyle(.secondary)
                } label: {
                    Label(AppLocalizer.text(.licenseAppCode, locale: appLocale), systemImage: "chevron.left.forwardslash.chevron.right")
                }

                LabeledContent {
                    Text(AppLocalizer.text(.licenseDataDescription, locale: appLocale))
                        .foregroundStyle(.secondary)
                } label: {
                    Label(AppLocalizer.text(.licenseData, locale: appLocale), systemImage: "book.closed")
                }

                LabeledContent {
                    Text(AppLocalizer.text(.licenseAudioDescription, locale: appLocale))
                        .foregroundStyle(.secondary)
                } label: {
                    Label(AppLocalizer.text(.licenseAudio, locale: appLocale), systemImage: "speaker.wave.2")
                }

                Link(destination: ministryCopyrightURL) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(AppLocalizer.text(.licenseMinistryCopyright, locale: appLocale), systemImage: "c.circle")
                        Text(ministryCopyrightURL.absoluteString)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section {
                NavigationLink {
                    LicenseOverviewScreen()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(AppLocalizer.text(.licenseThirdParty, locale: appLocale), systemImage: "swift")
                        Text(AppLocalizer.text(.licenseViewThirdParty, locale: appLocale))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle(AppLocalizer.text(.licenseTitle, locale: appLocale))
    }
}
