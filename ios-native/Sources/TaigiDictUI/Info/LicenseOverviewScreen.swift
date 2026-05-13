import SwiftUI
import TaigiDictCore

struct LicenseOverviewScreen: View {
    @Environment(\.locale) private var locale

    private var appLocale: AppLocale {
        AppLocalizer.appLocale(from: locale)
    }

    var body: some View {
        List {
            Section(AppLocalizer.text(.licenseOverviewCoreSection, locale: appLocale)) {
                ForEach(ThirdPartyLicenseCatalog.directDependencies) { entry in
                    NavigationLink {
                        ThirdPartyLicenseDetailScreen(entry: entry)
                    } label: {
                        thirdPartyRow(entry)
                    }
                }
            }

            Section(AppLocalizer.text(.licenseOverviewIOSSection, locale: appLocale)) {
                ForEach(ThirdPartyLicenseCatalog.bundledComponents) { entry in
                    NavigationLink {
                        ThirdPartyLicenseDetailScreen(entry: entry)
                    } label: {
                        thirdPartyRow(entry)
                    }
                }
            }
        }
        .navigationTitle(AppLocalizer.text(.licenseOverviewTitle, locale: appLocale))
    }

    @ViewBuilder
    private func thirdPartyRow(_ entry: ThirdPartyLicenseEntry) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(entry.name, systemImage: "shippingbox")

            Text(entry.summaryText())
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
