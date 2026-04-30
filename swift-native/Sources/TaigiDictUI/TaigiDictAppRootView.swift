import SwiftUI
import TaigiDictCore

public struct TaigiDictAppRootView: View {
    @State private var viewModel: DictionarySearchViewModel
    @State private var initializationViewModel = InitializationViewModel()

    public init(repository: any DictionaryRepositoryProtocol) {
        _viewModel = State(initialValue: DictionarySearchViewModel(repository: repository))
    }

    public var body: some View {
        Group {
            switch initializationViewModel.state {
            case .ready:
                mainTabView
            case .idle, .loading, .failed:
                InitializationScreen(state: initializationViewModel.state) {
                    initializationViewModel.retry()
                }
            }
        }
        .task(id: initializationViewModel.taskID) {
            await initializationViewModel.prepare(using: viewModel)
        }
    }

    private var mainTabView: some View {
        TabView {
            DictionarySearchScreen(viewModel: viewModel)
                .tabItem {
                    Label("辭典", systemImage: "book")
                }

            PlaceholderScreen(
                title: "書籤",
                systemImage: "bookmark",
                message: "書籤功能會在後續重構接入。"
            )
            .tabItem {
                Label("書籤", systemImage: "bookmark")
            }

            SettingsScreen(library: viewModel.library)
            .tabItem {
                Label("設定", systemImage: "gearshape")
            }
        }
    }
}

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

private struct DictionaryDetailView: View {
    var sourceEntry: DictionaryEntry?
    var openEntry: (DictionaryEntry) -> Void

    @State private var viewModel: WordDetailViewModel

    init(
        entry: DictionaryEntry?,
        library: DictionaryLibrary,
        openEntry: @escaping (DictionaryEntry) -> Void
    ) {
        self.sourceEntry = entry
        self.openEntry = openEntry
        _viewModel = State(initialValue: WordDetailViewModel(library: library))
    }

    var body: some View {
        List {
            if viewModel.isPreparing {
                Section {
                    HStack {
                        ProgressView()
                        Text("準備詞條內容")
                    }
                }
            } else if let errorMessage = viewModel.errorMessage {
                Section {
                    ContentUnavailableView(
                        "詞條載入失敗",
                        systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage)
                    )
                }
            } else if let entry = viewModel.entry {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(entry.hanji)
                            .font(.largeTitle.bold())
                        Text(entry.romanization)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        if !entry.type.isEmpty || !entry.category.isEmpty {
                            Text([entry.type, entry.category].filter { !$0.isEmpty }.joined(separator: " · "))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }

                RelationshipSection(
                    title: "異用字",
                    words: entry.variantChars,
                    openableWords: viewModel.openableWords,
                    openWord: openLinkedWord
                )

                RelationshipSection(
                    title: "近義詞",
                    words: entry.wordSynonyms,
                    openableWords: viewModel.openableWords,
                    openWord: openLinkedWord
                )

                RelationshipSection(
                    title: "反義詞",
                    words: entry.wordAntonyms,
                    openableWords: viewModel.openableWords,
                    openWord: openLinkedWord
                )

                ForEach(Array(entry.senses.enumerated()), id: \.offset) { _, sense in
                    Section(sense.partOfSpeech.isEmpty ? "解說" : sense.partOfSpeech) {
                        if !sense.definition.isEmpty {
                            Text(sense.definition)
                        }

                        RelationshipSectionContent(
                            title: "近義",
                            words: sense.definitionSynonyms,
                            openableWords: viewModel.openableWords,
                            openWord: openLinkedWord
                        )

                        RelationshipSectionContent(
                            title: "反義",
                            words: sense.definitionAntonyms,
                            openableWords: viewModel.openableWords,
                            openWord: openLinkedWord
                        )

                        ForEach(Array(sense.examples.enumerated()), id: \.offset) { _, example in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(example.hanji)
                                Text(example.romanization)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Text(example.mandarin)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                }

                DetailStringListSection(title: "又唸作", values: entry.alternativePronunciations)
                DetailStringListSection(title: "合音唸作", values: entry.contractedPronunciations)
                DetailStringListSection(title: "俗唸作", values: entry.colloquialPronunciations)
                DetailStringListSection(title: "語音差異", values: entry.phoneticDifferences)
                DetailStringListSection(title: "詞彙比較", values: entry.vocabularyComparisons)
            } else {
                ContentUnavailableView(
                    "開始搜尋",
                    systemImage: "text.magnifyingglass",
                    description: Text("選擇搜尋結果後，詞條內容會顯示在這裡。")
                )
            }
        }
        .toolbar {
            if viewModel.entry != nil {
                ShareLink(item: viewModel.shareText()) {
                    Label("分享", systemImage: "square.and.arrow.up")
                }
            }
        }
        .task(id: sourceEntry?.id) {
            guard let sourceEntry else {
                return
            }
            await viewModel.prepare(entry: sourceEntry)
        }
    }

    private func openLinkedWord(_ word: String) {
        Task {
            guard let linkedEntry = await viewModel.linkedEntry(for: word) else {
                return
            }
            openEntry(linkedEntry)
        }
    }
}

private struct RelationshipSection: View {
    var title: String
    var words: [String]
    var openableWords: Set<String>
    var openWord: (String) -> Void

    var body: some View {
        let visibleWords = normalizedWords
        if !visibleWords.isEmpty {
            Section(title) {
                RelationshipRows(
                    words: visibleWords,
                    openableWords: openableWords,
                    openWord: openWord
                )
            }
        }
    }

    private var normalizedWords: [String] {
        words.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

private struct RelationshipSectionContent: View {
    var title: String
    var words: [String]
    var openableWords: Set<String>
    var openWord: (String) -> Void

    var body: some View {
        let visibleWords = normalizedWords
        if !visibleWords.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                RelationshipRows(
                    words: visibleWords,
                    openableWords: openableWords,
                    openWord: openWord
                )
            }
        }
    }

    private var normalizedWords: [String] {
        words.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

private struct RelationshipRows: View {
    var words: [String]
    var openableWords: Set<String>
    var openWord: (String) -> Void

    var body: some View {
        ForEach(words, id: \.self) { word in
            if openableWords.contains(word) {
                Button {
                    openWord(word)
                } label: {
                    Label(word, systemImage: "arrowshape.turn.up.right")
                }
            } else {
                Text(word)
            }
        }
    }
}

private struct DetailStringListSection: View {
    var title: String
    var values: [String]

    var body: some View {
        let visibleValues = values.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if !visibleValues.isEmpty {
            Section(title) {
                ForEach(visibleValues, id: \.self) { value in
                    Text(value)
                }
            }
        }
    }
}

private struct PlaceholderScreen: View {
    var title: String
    var systemImage: String
    var message: String

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                title,
                systemImage: systemImage,
                description: Text(message)
            )
            .navigationTitle(title)
        }
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
