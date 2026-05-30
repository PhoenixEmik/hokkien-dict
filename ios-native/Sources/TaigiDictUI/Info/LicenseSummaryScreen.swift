import SwiftUI
import TaigiDictCore

public struct LicenseSummaryScreen: View {
    private let ministryCopyrightURL = URL(string: "https://sutian.moe.edu.tw/zh-hant/piantsip/pankhuan-singbing/")!

    @Environment(\.locale) private var locale

    private var appLocale: AppLocale {
        AppLocalizer.appLocale(from: locale)
    }

    public init() {}

    public var body: some View {
#if os(macOS)
        macLicenseContent
#else
        List {
            Section(AppLocalizer.text(.licenseSummarySection, locale: appLocale)) {
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
                    Label(AppLocalizer.text(.licenseMinistryCopyright, locale: appLocale), systemImage: "c.circle")
                }
            }

            Section {
                NavigationLink {
                    LicenseOverviewScreen()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(AppLocalizer.text(.licenseThirdParty, locale: appLocale), systemImage: "shippingbox")
                        Text(AppLocalizer.text(.licenseViewThirdParty, locale: appLocale))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(AppLocalizer.text(.licenseTitle, locale: appLocale))
#endif
    }

#if os(macOS)
    private var macLicenseContent: some View {
        List {
            Section(AppLocalizer.text(.licenseSummarySection, locale: appLocale)) {
                macLicenseRow(
                    title: AppLocalizer.text(.licenseAppCode, locale: appLocale),
                    systemImage: "chevron.left.forwardslash.chevron.right",
                    value: AppLocalizer.text(.licenseAppCodeDescription, locale: appLocale)
                )

                macLicenseRow(
                    title: AppLocalizer.text(.licenseData, locale: appLocale),
                    systemImage: "book.closed",
                    value: AppLocalizer.text(.licenseDataDescription, locale: appLocale)
                )

                macLicenseRow(
                    title: AppLocalizer.text(.licenseAudio, locale: appLocale),
                    systemImage: "speaker.wave.2",
                    value: AppLocalizer.text(.licenseAudioDescription, locale: appLocale)
                )

                Link(destination: ministryCopyrightURL) {
                    Label(AppLocalizer.text(.licenseMinistryCopyright, locale: appLocale), systemImage: "c.circle")
                }
            }

            Section(AppLocalizer.text(.licenseThirdParty, locale: appLocale)) {
                NavigationLink {
                    LicenseOverviewScreen()
                } label: {
                    LabeledContent {
                        Text(AppLocalizer.text(.licenseViewThirdParty, locale: appLocale))
                            .foregroundStyle(.secondary)
                    } label: {
                        Label(AppLocalizer.text(.licenseThirdParty, locale: appLocale), systemImage: "shippingbox")
                    }
                }
            }
        }
        .listStyle(.inset)
        .navigationTitle(AppLocalizer.text(.licenseTitle, locale: appLocale))
    }

    private func macLicenseRow(title: String, systemImage: String, value: String) -> some View {
        LabeledContent {
            Text(value)
                .foregroundStyle(.secondary)
        } label: {
            Label(title, systemImage: systemImage)
        }
    }
#endif
}
