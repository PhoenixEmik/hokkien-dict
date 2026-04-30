import SwiftUI
import TaigiDictCore

public struct DictionarySearchScreen: View {
    @Bindable private var viewModel: DictionarySearchViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    public init(viewModel: DictionarySearchViewModel) {
        _viewModel = Bindable(viewModel)
    }

    public var body: some View {
        if horizontalSizeClass == .regular {
            NavigationSplitView {
                DictionarySearchList(viewModel: viewModel, showsSelection: true)
                    .navigationTitle("辭典")
            } detail: {
                DictionaryDetailView(
                    entry: viewModel.selectedEntry,
                    library: viewModel.library
                ) { entry in
                    viewModel.select(entry)
                }
                .navigationTitle(viewModel.selectedEntry?.hanji ?? "辭典")
            }
        } else {
            NavigationStack {
                DictionarySearchList(viewModel: viewModel, showsSelection: false)
                    .navigationTitle("辭典")
                    .navigationDestination(item: $viewModel.detailEntry) { entry in
                        DictionaryDetailView(
                            entry: entry,
                            library: viewModel.library
                        ) { linkedEntry in
                            viewModel.select(linkedEntry)
                        }
                        .navigationTitle(entry.hanji)
                        .taigiInlineNavigationTitle()
                    }
            }
        }
    }
}

private struct DictionarySearchList: View {
    @Bindable var viewModel: DictionarySearchViewModel
    var showsSelection: Bool

    var body: some View {
        List {
            if viewModel.isLoading {
                Section {
                    HStack {
                        ProgressView()
                        Text("載入辭典資料中")
                    }
                }
            } else if let errorMessage = viewModel.errorMessage {
                Section {
                    ContentUnavailableView(
                        "載入失敗",
                        systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage)
                    )
                }
            } else if viewModel.normalizedQuery.isEmpty {
                SearchStartContent(history: viewModel.searchHistory) { query in
                    viewModel.applyHistoryQuery(query)
                } clearHistory: {
                    viewModel.clearSearchHistory()
                }
            } else if viewModel.isSearching {
                Section {
                    HStack {
                        ProgressView()
                        Text("搜尋中")
                    }
                }
            } else if viewModel.results.isEmpty {
                Section {
                    ContentUnavailableView(
                        "查無結果",
                        systemImage: "magnifyingglass",
                        description: Text("試試改用漢字、羅馬字或華語詞義。")
                    )
                }
            } else {
                Section("搜尋結果") {
                    ForEach(viewModel.results) { entry in
                        Button {
                            viewModel.select(entry)
                        } label: {
                            DictionaryEntryRow(entry: entry)
                        }
                        .foregroundStyle(.primary)
                        .listRowBackground(
                            showsSelection && viewModel.selectedEntry?.id == entry.id
                                ? Color.accentColor.opacity(0.12)
                                : nil
                        )
                    }
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "輸入台語漢字、白話字或華語詞義")
        .onChange(of: viewModel.searchText) { _, _ in
            viewModel.scheduleSearch()
        }
        .onSubmit(of: .search) {
            viewModel.submitSearch()
        }
    }
}

private struct SearchStartContent: View {
    var history: [String]
    var applyHistory: (String) -> Void
    var clearHistory: () -> Void

    var body: some View {
        Section {
            ContentUnavailableView(
                "開始搜尋",
                systemImage: "text.magnifyingglass",
                description: Text("輸入台語漢字、白話字，或華語釋義後才顯示詞條。")
            )
        }

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
                    Label("清除搜尋紀錄", systemImage: "trash")
                }
            } header: {
                Text("搜尋紀錄")
            }
        }
    }
}

private struct DictionaryEntryRow: View {
    var entry: DictionaryEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.hanji)
                .font(.headline)
            Text(entry.romanization)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if !entry.briefSummary.isEmpty {
                Text(entry.briefSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private extension View {
    @ViewBuilder
    func taigiInlineNavigationTitle() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}
