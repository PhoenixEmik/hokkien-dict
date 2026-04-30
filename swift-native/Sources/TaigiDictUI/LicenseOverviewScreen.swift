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
                Label("GRDB.swift", systemImage: "shippingbox")
                Label("SwiftyOpenCC", systemImage: "shippingbox")
            }

            Section(AppLocalizer.text(.licenseOverviewIOSSection, locale: appLocale)) {
                Label("SwiftUI", systemImage: "applelogo")
                Label("Foundation", systemImage: "applelogo")
                Label(AppLocalizer.text(.licenseOverviewAVFoundation, locale: appLocale), systemImage: "applelogo")
            }
        }
        .navigationTitle(AppLocalizer.text(.licenseOverviewTitle, locale: appLocale))
    }
}
