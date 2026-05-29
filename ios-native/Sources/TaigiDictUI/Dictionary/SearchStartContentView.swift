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
    @State private var isPresentingClearConfirmation = false

    var body: some View {
        if !history.isEmpty {
#if os(macOS)
            Group {
                Section {
                    ForEach(history, id: \.self) { query in
                        Button {
                            applyHistory(query)
                        } label: {
                            Label(query, systemImage: "clock.arrow.circlepath")
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    HStack(spacing: 8) {
                        Text(AppLocalizer.text(.searchHistoryTitle, locale: locale))
                        Spacer(minLength: 0)
                        Button(AppLocalizer.text(.clearSearchHistory, locale: locale)) {
                            isPresentingClearConfirmation = true
                        }
                        .buttonStyle(.plain)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .alert(
                AppLocalizer.text(.searchHistoryClearConfirmTitle, locale: locale),
                isPresented: $isPresentingClearConfirmation
            ) {
                Button(AppLocalizer.text(.commonCancel, locale: locale), role: .cancel) {}
                Button(AppLocalizer.text(.clearSearchHistory, locale: locale), role: .destructive) {
                    clearHistory()
                }
            }
#else
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
#endif
        }
    }
}
