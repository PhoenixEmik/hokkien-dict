import SwiftUI
import TaigiDictCore

struct InitializationScreen: View {
    var state: InitializationViewModel.State
    var retry: () -> Void
    @Environment(\.locale) private var locale

    private var appLocale: AppLocale {
        AppLocalizer.appLocale(from: locale)
    }

    var body: some View {
        switch state {
        case .failed(let reason):
            ContentUnavailableView {
                Label(AppLocalizer.text(.initializationFailedTitle, locale: appLocale), systemImage: "exclamationmark.triangle")
            } description: {
                Text(failureMessage(reason: reason))
            } actions: {
                Button(AppLocalizer.text(.initializationRetry, locale: appLocale), action: retry)
            }
        case .idle, .loading, .ready:
            ContentUnavailableView {
                Label(AppLocalizer.text(.initializationLoadingTitle, locale: appLocale), systemImage: "book")
            } description: {
                VStack(spacing: 12) {
                    ProgressView()
                    Text(AppLocalizer.text(.initializationLoadingDescription, locale: appLocale))
                }
            }
        }
    }

    private func failureMessage(reason: InitializationViewModel.FailureReason) -> String {
        switch reason {
        case .library(let message):
            return message
        case .initializationIncomplete:
            return AppLocalizer.text(.initializationIncomplete, locale: appLocale)
        }
    }
}