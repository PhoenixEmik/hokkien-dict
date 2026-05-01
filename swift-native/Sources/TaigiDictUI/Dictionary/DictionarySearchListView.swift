import SwiftUI
import TaigiDictCore

struct DictionarySearchListView: View {
    @Bindable var viewModel: DictionarySearchViewModel
    var showsSelection: Bool
    var startPresentation: DictionarySearchStartPresentation = .full
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
                    viewModel.select(matched)
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
                if startPresentation.showsStartContent {
                    SearchStartContentView(history: viewModel.searchHistory, locale: appLocale) { query in
                        viewModel.applyHistoryQuery(query)
                    } clearHistory: {
                        Task {
                            await viewModel.clearSearchHistory()
                        }
                    }
                } else {
                    SearchHistoryContentView(history: viewModel.searchHistory, locale: appLocale) { query in
                        viewModel.applyHistoryQuery(query)
                    } clearHistory: {
                        Task {
                            await viewModel.clearSearchHistory()
                        }
                    }
                }
            } else if viewModel.isSearching {
                Section {
                    ForEach(0..<2, id: \.self) { _ in
                        SearchResultSkeletonRow()
                    }
                }
                .transition(.opacity)
            } else if viewModel.results.isEmpty {
                Section {
                    ContentUnavailableView(
                        AppLocalizer.text(.noResultTitle, locale: appLocale),
                        systemImage: "magnifyingglass",
                        description: Text(AppLocalizer.text(.noResultDescription, locale: appLocale))
                    )
                }
                .transition(.opacity)
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
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.12), value: viewModel.isSearching)
        .animation(.easeOut(duration: 0.12), value: viewModel.results.isEmpty)
        .searchable(text: $viewModel.searchText, prompt: AppLocalizer.text(.searchPrompt, locale: appLocale))
        .onChange(of: viewModel.searchText) { _, _ in
            viewModel.scheduleSearch()
        }
        .onSubmit(of: .search) {
            viewModel.submitSearch()
        }
    }
}

enum DictionarySearchStartPresentation: Equatable {
    case full
    case historyOnly

    var showsStartContent: Bool {
        self == .full
    }
}

private struct SearchResultSkeletonRow: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 5)
                .fill(.quaternary)
                .frame(width: 48, height: 16)

            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 5)
                    .fill(.quaternary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 14)

                RoundedRectangle(cornerRadius: 4)
                    .fill(.quaternary)
                    .frame(width: 120, height: 12)
            }
        }
        .padding(.vertical, 6)
        .accessibilityHidden(true)
    }
}
