import SwiftUI
import TaigiDictCore

public struct LicenseOverviewScreen: View {
    @Environment(\.locale) private var locale

    private var appLocale: AppLocale {
        AppLocalizer.appLocale(from: locale)
    }

    public init() {}

    public var body: some View {
        List {
            Section(AppLocalizer.text(.licenseOverviewCoreSection, locale: appLocale)) {
                ForEach(ThirdPartyLicenseCatalog.directDependencies) { entry in
                    thirdPartyEntryRow(entry)
                }
            }

            Section(AppLocalizer.text(.licenseOverviewIOSSection, locale: appLocale)) {
                ForEach(ThirdPartyLicenseCatalog.bundledComponents) { entry in
                    thirdPartyEntryRow(entry)
                }
            }
        }
        .listStyle(.inset)
#if os(iOS)
        .navigationTitle(AppLocalizer.text(.licenseOverviewTitle, locale: appLocale))
        .navigationBarTitleDisplayMode(.inline)
#endif
    }

    @ViewBuilder
    private func thirdPartyEntryRow(_ entry: ThirdPartyLicenseEntry) -> some View {
        NavigationLink {
            ThirdPartyLicenseDetailScreen(entry: entry)
        } label: {
            thirdPartyRow(entry)
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
