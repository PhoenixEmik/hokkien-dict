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
        let splashContent = SplashScreenContent.resolve(locale: appLocale)

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
            ZStack {
                SplashBackground()
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Image("SplashIcon", bundle: .module)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 96, height: 96)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .accessibilityHidden(true)

                    VStack(spacing: 8) {
                        Text(splashContent.title)
                            .font(.largeTitle.bold())
                            .multilineTextAlignment(.center)

                        Text(splashContent.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Group {
                        if let progress {
                            ProgressView(value: progress)
                        } else {
                            ProgressView()
                        }
                    }
                    .frame(maxWidth: 180)
                    .accessibilityLabel(AppLocalizer.text(.initializationLoadingDescription, locale: appLocale))
                }
                .padding(32)
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

struct SplashScreenContent: Equatable {
    var title: String
    var description: String

    static func resolve(locale: AppLocale) -> SplashScreenContent {
        SplashScreenContent(
            title: AppLocalizer.text(.aboutAppSection, locale: locale),
            description: AppLocalizer.text(.aboutAppDescription, locale: locale)
        )
    }
}

private struct SplashBackground: View {
    var body: some View {
        #if os(iOS)
        Color(.systemBackground)
        #elseif os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color.clear
        #endif
    }
}
