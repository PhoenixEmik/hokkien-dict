import SwiftUI
import TaigiDictCore

struct SearchStartContentView: View {
    var history: [String]
    var locale: AppLocale
    var applyHistory: (String) -> Void
    var clearHistory: () -> Void

    var body: some View {
        Section {
            ContentUnavailableView(
                AppLocalizer.text(.searchStartTitle, locale: locale),
                systemImage: "text.magnifyingglass",
                description: Text(AppLocalizer.text(.searchStartDescription, locale: locale))
            )
        }

        SearchHistoryContentView(
            history: history,
            locale: locale,
            applyHistory: applyHistory,
            clearHistory: clearHistory
        )
    }
}

struct SearchHistoryContentView: View {
    var history: [String]
    var locale: AppLocale
    var applyHistory: (String) -> Void
    var clearHistory: () -> Void

    var body: some View {
        if !history.isEmpty {
            Section {
                ForEach(history, id: \.self) { query in
                    Button {
                        applyHistory(query)
                    } label: {
                        Label(query, systemImage: "clock.arrow.circlepath")
                    }
                }
                Button(role: .destructive, action: clearHistory) {
                    Label(AppLocalizer.text(.clearSearchHistory, locale: locale), systemImage: "trash")
                }
            } header: {
                Text(AppLocalizer.text(.searchHistoryTitle, locale: locale))
            }
        }
    }
}
