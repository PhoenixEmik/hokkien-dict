import SwiftUI
import TaigiDictCore

struct AboutScreen: View {
    @Environment(\.locale) private var locale

    private var appLocale: AppLocale {
        AppLocalizer.appLocale(from: locale)
    }

    var body: some View {
        List {
            Section(AppLocalizer.text(.aboutAppSection, locale: appLocale)) {
                Text(AppLocalizer.text(.aboutAppDescription, locale: appLocale))
                LabeledContent(AppLocalizer.text(.aboutVersion, locale: appLocale)) {
                    Text(AppLocalizer.text(.aboutVersionValue, locale: appLocale))
                }
            }

            Section(AppLocalizer.text(.aboutProjectSection, locale: appLocale)) {
                Link(AppLocalizer.text(.aboutGitHub, locale: appLocale), destination: URL(string: "https://github.com/PhoenixEmik/hokkien-app")!)
                Link(AppLocalizer.text(.aboutPrivacy, locale: appLocale), destination: URL(string: "https://app.taigidict.org/privacy")!)
            }
        }
        .navigationTitle(AppLocalizer.text(.aboutTitle, locale: appLocale))
    }
}
