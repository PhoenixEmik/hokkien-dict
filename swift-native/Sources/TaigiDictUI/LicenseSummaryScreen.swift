import SwiftUI
import TaigiDictCore

struct LicenseSummaryScreen: View {
    @Environment(\.locale) private var locale

    private var appLocale: AppLocale {
        AppLocalizer.appLocale(from: locale)
    }

    var body: some View {
        List {
            Section(AppLocalizer.text(.licenseSummarySection, locale: appLocale)) {
                Label(AppLocalizer.text(.licenseAppCode, locale: appLocale), systemImage: "checkmark.seal")
                Label(AppLocalizer.text(.licenseData, locale: appLocale), systemImage: "checkmark.seal")
                Label(AppLocalizer.text(.licenseAudio, locale: appLocale), systemImage: "checkmark.seal")
                Label(AppLocalizer.text(.licenseThirdParty, locale: appLocale), systemImage: "checkmark.seal")
            }

            Section {
                NavigationLink(AppLocalizer.text(.licenseViewThirdParty, locale: appLocale)) {
                    LicenseOverviewScreen()
                }
            }
        }
        .navigationTitle(AppLocalizer.text(.licenseTitle, locale: appLocale))
    }
}
