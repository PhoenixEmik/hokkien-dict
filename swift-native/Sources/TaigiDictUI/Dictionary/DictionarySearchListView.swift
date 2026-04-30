import SwiftUI
import TaigiDictCore

struct DictionarySearchListView: View {
    @Bindable var viewModel: DictionarySearchViewModel
    var showsSelection: Bool
    @Environment(\.locale) private var locale

    private var appLocale: AppLocale {
        AppLocalizer.appLocale(from: locale)
    }

    private var selectedEntryID: Binding<Int64?> {
        Binding(
            get: { viewModel.selectedEntry?.id },
            set: { newID in
                guard let newID else {
                    viewModel.selectedEntry = nil
                    return
                }

                if let matched = viewModel.results.first(where: { $0.id == newID }) {
                    viewModel.selectedEntry = matched
                }
            }
        )
    }

    var body: some View {
        List(selection: showsSelection ? selectedEntryID : .constant(nil)) {
            if viewModel.isLoading {
                Section {
                    HStack {
                        ProgressView()
                        Text(AppLocalizer.text(.loadingDictionary, locale: appLocale))
                    }
                }
            } else if let errorMessage = viewModel.errorMessage {
                Section {
                    ContentUnavailableView(
                        AppLocalizer.text(.loadingFailedTitle, locale: appLocale),
                        systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage)
                    )
                }
            } else if viewModel.normalizedQuery.isEmpty {
                SearchStartContentView(history: viewModel.searchHistory, locale: appLocale) { query in
                    viewModel.applyHistoryQuery(query)
                } clearHistory: {
                    Task {
                        await viewModel.clearSearchHistory()
                    }
                }
            } else if viewModel.isSearching {
                Section {
                    HStack {
                        ProgressView()
                        Text(AppLocalizer.text(.searching, locale: appLocale))
                    }
                }
            } else if viewModel.results.isEmpty {
                Section {
                    ContentUnavailableView(
                        AppLocalizer.text(.noResultTitle, locale: appLocale),
                        systemImage: "magnifyingglass",
                        description: Text(AppLocalizer.text(.noResultDescription, locale: appLocale))
                    )
                }
            } else {
                Section(AppLocalizer.text(.searchResultsSection, locale: appLocale)) {
                    ForEach(viewModel.results) { entry in
                        if showsSelection {
                            DictionaryEntryRowView(entry: entry)
                                .tag(entry.id)
                        } else {
                            Button {
                                viewModel.select(entry)
                            } label: {
                                DictionaryEntryRowView(entry: entry)
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: AppLocalizer.text(.searchPrompt, locale: appLocale))
        .onChange(of: viewModel.searchText) { _, _ in
            viewModel.scheduleSearch()
        }
        .onSubmit(of: .search) {
            viewModel.submitSearch()
        }
    }
}
