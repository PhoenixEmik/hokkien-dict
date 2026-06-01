#if os(macOS)
import SwiftUI
import TaigiDictCore

struct MacLicenseBrowserView: View {
    @Environment(\.locale) private var locale
    @State private var selection: LicenseSidebarCategory? = .summary

    private var appLocale: AppLocale {
        AppLocalizer.appLocale(from: locale)
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(LicenseSidebarCategory.allCases) { category in
                    Label(category.title(locale: appLocale), systemImage: category.systemImage)
                        .tag(category)
                }
            }
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 220, ideal: 260)
        } detail: {
            NavigationStack {
                if let selection {
                    categoryRoot(for: selection)
                } else {
                    ContentUnavailableView(
                        AppLocalizer.text(.licenseTitle, locale: appLocale),
                        systemImage: "doc.text",
                        description: Text(AppLocalizer.text(.licenseViewThirdParty, locale: appLocale))
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func categoryRoot(for category: LicenseSidebarCategory) -> some View {
        switch category {
        case .summary:
            List {
                Section(AppLocalizer.text(.licenseSummarySection, locale: appLocale)) {
                    ForEach(LicenseSummaryItem.allCases) { item in
                        NavigationLink(value: LicenseBrowserDestination.summary(item)) {
                            Label(item.title(locale: appLocale), systemImage: item.systemImage)
                        }
                    }
                }
            }
            .listStyle(.inset)
            .navigationTitle(category.title(locale: appLocale))
            .navigationDestination(for: LicenseBrowserDestination.self) { destination in
                destinationDetail(for: destination)
            }

        case .directDependencies:
            List {
                Section(AppLocalizer.text(.licenseOverviewCoreSection, locale: appLocale)) {
                    ForEach(ThirdPartyLicenseCatalog.directDependencies) { entry in
                        NavigationLink(value: LicenseBrowserDestination.thirdParty(entry.id)) {
                            thirdPartyRow(entry)
                        }
                    }
                }
            }
            .listStyle(.inset)
            .navigationTitle(category.title(locale: appLocale))
            .navigationDestination(for: LicenseBrowserDestination.self) { destination in
                destinationDetail(for: destination)
            }

        case .bundledComponents:
            List {
                Section(AppLocalizer.text(.licenseOverviewIOSSection, locale: appLocale)) {
                    ForEach(ThirdPartyLicenseCatalog.bundledComponents) { entry in
                        NavigationLink(value: LicenseBrowserDestination.thirdParty(entry.id)) {
                            thirdPartyRow(entry)
                        }
                    }
                }
            }
            .listStyle(.inset)
            .navigationTitle(category.title(locale: appLocale))
            .navigationDestination(for: LicenseBrowserDestination.self) { destination in
                destinationDetail(for: destination)
            }
        }
    }

    @ViewBuilder
    private func destinationDetail(for destination: LicenseBrowserDestination) -> some View {
        switch destination {
        case .summary(let item):
            MacLicenseSummaryDetailView(item: item, appLocale: appLocale)

        case .thirdParty(let entryID):
            if let entry = ThirdPartyLicenseCatalog.entry(id: entryID) {
                ThirdPartyLicenseDetailScreen(entry: entry)
            } else {
                ContentUnavailableView(
                    AppLocalizer.text(.licenseTitle, locale: appLocale),
                    systemImage: "doc.text",
                    description: Text(AppLocalizer.text(.licenseViewThirdParty, locale: appLocale))
                )
            }
        }
    }

    private func thirdPartyRow(_ entry: ThirdPartyLicenseEntry) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(entry.name, systemImage: "shippingbox")

            Text(entry.summaryText())
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

private enum LicenseSidebarCategory: String, CaseIterable, Identifiable {
    case summary
    case directDependencies
    case bundledComponents

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .summary:
            return "doc.text"
        case .directDependencies, .bundledComponents:
            return "shippingbox"
        }
    }

    func title(locale: AppLocale) -> String {
        switch self {
        case .summary:
            return AppLocalizer.text(.licenseSummarySection, locale: locale)
        case .directDependencies:
            return AppLocalizer.text(.licenseOverviewCoreSection, locale: locale)
        case .bundledComponents:
            return AppLocalizer.text(.licenseOverviewIOSSection, locale: locale)
        }
    }
}

private enum LicenseBrowserDestination: Hashable {
    case summary(LicenseSummaryItem)
    case thirdParty(String)
}

private enum LicenseSummaryItem: String, CaseIterable, Identifiable, Hashable {
    case appCode
    case data
    case audio
    case ministryCopyright

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .appCode:
            return "chevron.left.forwardslash.chevron.right"
        case .data:
            return "book.closed"
        case .audio:
            return "speaker.wave.2"
        case .ministryCopyright:
            return "c.circle"
        }
    }

    func title(locale: AppLocale) -> String {
        switch self {
        case .appCode:
            return AppLocalizer.text(.licenseAppCode, locale: locale)
        case .data:
            return AppLocalizer.text(.licenseData, locale: locale)
        case .audio:
            return AppLocalizer.text(.licenseAudio, locale: locale)
        case .ministryCopyright:
            return AppLocalizer.text(.licenseMinistryCopyright, locale: locale)
        }
    }

    func value(locale: AppLocale) -> String? {
        switch self {
        case .appCode:
            return AppLocalizer.text(.licenseAppCodeDescription, locale: locale)
        case .data:
            return AppLocalizer.text(.licenseDataDescription, locale: locale)
        case .audio:
            return AppLocalizer.text(.licenseAudioDescription, locale: locale)
        case .ministryCopyright:
            return nil
        }
    }
}

private struct MacLicenseSummaryDetailView: View {
    let item: LicenseSummaryItem
    let appLocale: AppLocale

    private let ministryCopyrightURL = URL(string: "https://sutian.moe.edu.tw/zh-hant/piantsip/pankhuan-singbing/")!

    var body: some View {
        List {
            Section(AppLocalizer.text(.licenseSummarySection, locale: appLocale)) {
                Label(item.title(locale: appLocale), systemImage: item.systemImage)

                if let value = item.value(locale: appLocale) {
                    Text(value)
                        .foregroundStyle(.secondary)
                }

                if case .ministryCopyright = item {
                    Link(AppLocalizer.text(.licenseMinistryCopyright, locale: appLocale), destination: ministryCopyrightURL)
                }
            }
        }
        .listStyle(.inset)
        .navigationTitle(item.title(locale: appLocale))
    }
}
#endif
