import SwiftUI
import TaigiDictCore

struct InitializationScreen: View {
    var phase: InitializationPhase
    var progress: Double?
    var errorMessage: String?
    var failureReason: InitializationViewModel.FailureReason?
    var retry: () -> Void
    @Environment(\.locale) private var locale

    private var appLocale: AppLocale {
        AppLocalizer.appLocale(from: locale)
    }

    var body: some View {
        switch phase {
        case .failed:
            ContentUnavailableView {
                Label(AppLocalizer.text(.initializationFailedTitle, locale: appLocale), systemImage: "exclamationmark.triangle")
            } description: {
                Text(failureMessage)
            } actions: {
                Button(AppLocalizer.text(.initializationRetry, locale: appLocale), action: retry)
            }
        case .idle, .loading, .ready:
            ContentUnavailableView {
                Label(AppLocalizer.text(.initializationLoadingTitle, locale: appLocale), systemImage: "book")
            } description: {
                VStack(spacing: 12) {
                    if let progress {
                        ProgressView(value: progress)
                    } else {
                        ProgressView()
                    }
                    Text(AppLocalizer.text(.initializationLoadingDescription, locale: appLocale))
                }
            }
        }
    }

    private var failureMessage: String {
        if let errorMessage, !errorMessage.isEmpty {
            return errorMessage
        }

        switch failureReason {
        case .library(let message):
            return message
        case .initializationIncomplete, .none:
            return AppLocalizer.text(.initializationIncomplete, locale: appLocale)
        }
    }
}