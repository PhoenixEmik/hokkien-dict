import SwiftUI
import TaigiDictCore

struct DictionaryDetailView: View {
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
