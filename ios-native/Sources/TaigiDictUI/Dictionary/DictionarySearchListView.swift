import SwiftUI
import TaigiDictCore

struct DictionarySearchListView: View {
    @Bindable var viewModel: DictionarySearchViewModel
    var showsSelection: Bool
    var startPresentation: DictionarySearchStartPresentation = .full
    var selectedEntryID: Binding<Int64?>? = nil
    var onHistoryQuerySelected: ((String) -> Void)? = nil
    var onUserSelectEntry: ((DictionaryEntry) -> Void)? = nil
    @Environment(\.locale) private var locale

    private var appLocale: AppLocale {
        AppLocalizer.appLocale(from: locale)
    }

    private var selectedEntryIDBinding: Binding<Int64?> {
        if let selectedEntryID {
            return Binding(
                get: { selectedEntryID.wrappedValue },
                set: { newID in
                    if newID == nil,
                       selectedEntryID.wrappedValue != nil,
                       !viewModel.results.isEmpty {
                        return
                    }
                    selectedEntryID.wrappedValue = newID
                    updateSelection(newID, recordsUserSelection: true)
                }
            )
        }

        return Binding(
            get: { viewModel.selectedEntry?.id },
            set: { newID in
                updateSelection(newID, recordsUserSelection: true)
            }
        )
    }

    private func updateSelection(_ newID: Int64?, recordsUserSelection: Bool = false) {
        guard let newID else {
            viewModel.selectedEntry = nil
            viewModel.detailEntry = nil
            return
        }

        if let matched = viewModel.results.first(where: { $0.id == newID }) {
            if recordsUserSelection {
                viewModel.select(matched)
                onUserSelectEntry?(matched)
            } else {
                viewModel.selectedEntry = matched
                viewModel.detailEntry = matched
            }
        }
    }

    var body: some View {
        List(selection: showsSelection ? selectedEntryIDBinding : .constant(nil)) {
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
                    } onHistoryQuerySelected: { query in
                        onHistoryQuerySelected?(query)
                    }
                } else {
                    SearchHistoryContentView(history: viewModel.searchHistory, locale: appLocale) { query in
                        viewModel.applyHistoryQuery(query)
                    } clearHistory: {
                        Task {
                            await viewModel.clearSearchHistory()
                        }
                    } onHistoryQuerySelected: { query in
                        onHistoryQuerySelected?(query)
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
#if os(macOS)
                EmptyView()
#else
                Section {
                    ContentUnavailableView(
                        AppLocalizer.text(.noResultTitle, locale: appLocale),
                        systemImage: "magnifyingglass",
                        description: Text(AppLocalizer.text(.noResultDescription, locale: appLocale))
                    )
                }
                .transition(.opacity)
#endif
            } else {
                Section(AppLocalizer.text(.searchResultsSection, locale: appLocale)) {
                    ForEach(viewModel.results) { entry in
                        if showsSelection {
                            DictionaryEntryRowView(entry: entry, layoutStyle: .sidebarCompact)
                                .tag(entry.id)
                        } else {
                            Button {
                                viewModel.select(entry)
                                onUserSelectEntry?(entry)
                            } label: {
                                DictionaryEntryRowView(entry: entry, layoutStyle: .standard)
                            }
                            .foregroundStyle(.primary)
                            .accessibilityIdentifier("dictionary.entry.\(entry.id)")
                        }
                    }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.12), value: viewModel.isSearching)
        .animation(.easeOut(duration: 0.12), value: viewModel.results.isEmpty)
        .dictionarySearchInput(viewModel: viewModel, locale: appLocale)
    }
}

enum DictionarySearchStartPresentation: Equatable {
    case full
    case historyOnly

    var showsStartContent: Bool {
        self == .full
    }
}

struct SearchResultSkeletonRow: View {
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
