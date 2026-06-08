import SwiftUI
import TaigiDictCore

struct DictionaryDetailView: View {
    var sourceEntry: DictionaryEntry?
    @Environment(\.locale) private var locale
    private let library: DictionaryLibrary
    private let bookmarkStore: (any BookmarksStoreProtocol)?
    private let offlineAudioStore: (any OfflineAudioManaging)?
    private let conversionService: (any ChineseConversionProviding)?
    private let onBookmarkChanged: (() -> Void)?
    private let onOpenLinkedWord: ((String) -> Void)?

    @State private var viewModel: WordDetailViewModel
    @State private var isBookmarked = false
    @State private var linkedEntry: DictionaryEntry?
    init(
        entry: DictionaryEntry?,
        library: DictionaryLibrary,
        bookmarkStore: (any BookmarksStoreProtocol)? = nil,
        offlineAudioStore: (any OfflineAudioManaging)? = nil,
        conversionService: (any ChineseConversionProviding)? = nil,
        onBookmarkChanged: (() -> Void)? = nil,
        onOpenLinkedWord: ((String) -> Void)? = nil
    ) {
        self.sourceEntry = entry
        self.library = library
        self.bookmarkStore = bookmarkStore
        self.offlineAudioStore = offlineAudioStore
        self.conversionService = conversionService
        self.onBookmarkChanged = onBookmarkChanged
        self.onOpenLinkedWord = onOpenLinkedWord
        _viewModel = State(
            initialValue: WordDetailViewModel(
                library: library,
                offlineAudioStore: offlineAudioStore,
                conversionService: conversionService
            )
        )
        _isBookmarked = State(
            initialValue: {
                guard let entry, let bookmarkStore = bookmarkStore as? BookmarkStore else {
                    return false
                }
                return bookmarkStore.containsPersistedBookmark(entry.id)
            }()
        )
    }

    private var appLocale: AppLocale {
        AppLocalizer.appLocale(from: locale)
    }

    private var displayedEntry: DictionaryEntry? {
        viewModel.entry ?? sourceEntry
    }

    var body: some View {
        List {
            if let errorMessage = viewModel.errorMessage {
                Section {
                    ContentUnavailableView(
                        AppLocalizer.text(.detailLoadFailedTitle, locale: appLocale),
                        systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage)
                    )
                }
            } else if let entry = displayedEntry {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text(entry.hanji)
                                .taigiReadingFont(.largeTitle, weight: .bold)

                            if !entry.audioID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Button {
                                    Task {
                                        await viewModel.playWordAudio()
                                    }
                                } label: {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .font(.title2)
                                }
                                .buttonStyle(.borderless)
                                .accessibilityLabel(AppLocalizer.text(.playWordAudio, locale: appLocale))
                            }
                        }
                        Text(entry.romanization)
                            .taigiReadingFont(.title3)
                            .foregroundStyle(.secondary)
                        if !entry.type.isEmpty || !entry.category.isEmpty {
                            Text([entry.type, entry.category].filter { !$0.isEmpty }.joined(separator: " · "))
                                .taigiReadingFont(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }

                if entry.hasDisplayableDetailContent {
                    RelationshipSection(
                        title: AppLocalizer.text(.relationshipsVariant, locale: appLocale),
                        words: entry.variantChars,
                        openableWords: viewModel.openableWords,
                        openWord: openLinkedWord
                    )

                    RelationshipSection(
                        title: AppLocalizer.text(.relationshipsSynonym, locale: appLocale),
                        words: entry.wordSynonyms,
                        openableWords: viewModel.openableWords,
                        openWord: openLinkedWord
                    )

                    RelationshipSection(
                        title: AppLocalizer.text(.relationshipsAntonym, locale: appLocale),
                        words: entry.wordAntonyms,
                        openableWords: viewModel.openableWords,
                        openWord: openLinkedWord
                    )

                    ForEach(indexedSenses(for: entry)) { indexedSense in
                        let sense = indexedSense.sense
                        let headerTitle = sense.partOfSpeech.isEmpty
                            ? AppLocalizer.text(.definitionFallbackTitle, locale: appLocale)
                            : sense.partOfSpeech

                        Section {
                            if !sense.definition.isEmpty {
                                LinkedReferenceText(sense.definition, openWord: openLinkedWord)
                                    .taigiReadingFont(.body)
                            }

                            RelationshipSectionContent(
                                title: AppLocalizer.text(.definitionSynonym, locale: appLocale),
                                words: sense.definitionSynonyms,
                                openableWords: viewModel.openableWords,
                                openWord: openLinkedWord
                            )

                            RelationshipSectionContent(
                                title: AppLocalizer.text(.definitionAntonym, locale: appLocale),
                                words: sense.definitionAntonyms,
                                openableWords: viewModel.openableWords,
                                openWord: openLinkedWord
                            )

                            ForEach(indexedExamples(for: indexedSense)) { indexedExample in
                                let example = indexedExample.example
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                                        Text(example.hanji)
                                            .taigiReadingFont(.body)

                                        if !example.audioID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                            Button {
                                                Task {
                                                    await viewModel.playExampleAudio(example)
                                                }
                                            } label: {
                                                Image(systemName: "speaker.wave.2.fill")
                                                    .font(.title3)
                                            }
                                            .buttonStyle(.borderless)
                                            .accessibilityLabel(AppLocalizer.text(.playExampleAudio, locale: appLocale))
                                        }
                                    }

                                    Text(example.romanization)
                                        .taigiReadingFont(.subheadline)
                                        .foregroundStyle(.secondary)
                                    LinkedReferenceText(example.mandarin, openWord: openLinkedWord)
                                        .taigiReadingFont(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .accessibilityElement(children: .combine)
                            }
                        } header: {
                            DetailSectionHeader(headerTitle)
                        }
                    }

                    DetailStringListSection(
                        title: AppLocalizer.text(.detailAlternativePronunciationsTitle, locale: appLocale),
                        values: entry.alternativePronunciations
                    )
                    DetailStringListSection(
                        title: AppLocalizer.text(.detailContractedPronunciationsTitle, locale: appLocale),
                        values: entry.contractedPronunciations
                    )
                    DetailStringListSection(
                        title: AppLocalizer.text(.detailColloquialPronunciationsTitle, locale: appLocale),
                        values: entry.colloquialPronunciations
                    )
                    DetailStringListSection(
                        title: AppLocalizer.text(.detailPhoneticDifferencesTitle, locale: appLocale),
                        values: entry.phoneticDifferences
                    )
                    DetailStringListSection(
                        title: AppLocalizer.text(.detailVocabularyComparisonsTitle, locale: appLocale),
                        values: entry.vocabularyComparisons
                    )
                } else if !entry.briefSummary.isEmpty {
                    Section {
                        Text(entry.briefSummary)
                            .taigiReadingFont(.body)
                            .foregroundStyle(.secondary)
                    } header: {
                        DetailSectionHeader(AppLocalizer.text(.definitionFallbackTitle, locale: appLocale))
                    }
                }
            } else {
                ContentUnavailableView(
                    AppLocalizer.text(.searchStartDetailTitle, locale: appLocale),
                    systemImage: "text.magnifyingglass",
                    description: Text(AppLocalizer.text(.searchStartDetailDescription, locale: appLocale))
                )
            }
        }
        .detailToolbar(
            displayedEntry: displayedEntry,
            bookmarkStore: bookmarkStore,
            appLocale: appLocale,
            isBookmarked: isBookmarked,
            toggleBookmark: toggleBookmark
        )
        .navigationDestination(item: $linkedEntry) { entry in
            DictionaryDetailView(
                entry: entry,
                library: library,
                bookmarkStore: bookmarkStore,
                offlineAudioStore: offlineAudioStore,
                conversionService: conversionService
            )
            .navigationTitle(entry.hanji)
            .taigiInlineNavigationTitle()
        }
        .task(id: sourceEntry?.id) {
            guard let sourceEntry else {
                viewModel.clear()
                isBookmarked = false
                linkedEntry = nil
                return
            }
            await refreshBookmarkState(entryID: sourceEntry.id)
            guard !Task.isCancelled else {
                return
            }
            await viewModel.prepare(entry: sourceEntry, locale: appLocale)
            guard !Task.isCancelled else {
                return
            }
            await refreshBookmarkState()
        }
        .alert(
            AppLocalizer.text(.audioPlaybackAlertTitle, locale: appLocale),
            isPresented: Binding(
                get: { viewModel.audioAlertMessage != nil },
                set: { isPresented in
                    if !isPresented {
                        viewModel.dismissAudioAlert()
                    }
                }
            )
        ) {
            Button(AppLocalizer.text(.commonOK, locale: appLocale), role: .cancel) {
                viewModel.dismissAudioAlert()
            }
        } message: {
            Text(viewModel.audioAlertMessage ?? "")
        }
    }

    private func openLinkedWord(_ word: String) {
        if let onOpenLinkedWord {
            onOpenLinkedWord(word)
            return
        }

        Task {
            guard let linkedEntry = await viewModel.linkedEntry(for: word, locale: appLocale) else {
                return
            }
            self.linkedEntry = linkedEntry
        }
    }

    private func toggleBookmark(_ entry: DictionaryEntry) {
        guard let bookmarkStore else {
            return
        }

        Task {
            let bookmarked = await bookmarkStore.toggleBookmark(entryID: entry.id)
            await MainActor.run {
                isBookmarked = bookmarked
                onBookmarkChanged?()
            }
        }
    }

    private func refreshBookmarkState() async {
        guard let entry = viewModel.entry, bookmarkStore != nil else {
            isBookmarked = false
            return
        }

        await refreshBookmarkState(entryID: entry.id)
    }

    private func refreshBookmarkState(entryID: Int64) async {
        guard let bookmarkStore else {
            isBookmarked = false
            return
        }

        let bookmarked = await bookmarkStore.isBookmarked(entryID)
        guard !Task.isCancelled else {
            return
        }
        isBookmarked = bookmarked
    }

    private func indexedSenses(for entry: DictionaryEntry) -> [IndexedSense] {
        entry.senses.enumerated().map { offset, sense in
            IndexedSense(entryID: entry.id, index: offset, sense: sense)
        }
    }

    private func indexedExamples(for indexedSense: IndexedSense) -> [IndexedExample] {
        indexedSense.sense.examples.enumerated().map { offset, example in
            IndexedExample(parentSenseID: indexedSense.id, index: offset, example: example)
        }
    }
}

private extension DictionaryEntry {
    var hasDisplayableDetailContent: Bool {
        senses.contains { sense in
            !sense.partOfSpeech.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || !sense.definition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || !sense.definitionSynonyms.isEmpty
                || !sense.definitionAntonyms.isEmpty
                || !sense.examples.isEmpty
        }
        || !variantChars.isEmpty
        || !wordSynonyms.isEmpty
        || !wordAntonyms.isEmpty
        || !alternativePronunciations.isEmpty
        || !contractedPronunciations.isEmpty
        || !colloquialPronunciations.isEmpty
        || !phoneticDifferences.isEmpty
        || !vocabularyComparisons.isEmpty
    }
}

private struct IndexedSense: Identifiable {
    let entryID: Int64
    let index: Int
    let sense: DictionarySense

    var id: String {
        "\(entryID)-sense-\(index)-\(sense.partOfSpeech)-\(sense.definition)"
    }
}

private struct IndexedExample: Identifiable {
    let parentSenseID: String
    let index: Int
    let example: DictionaryExample

    var id: String {
        "\(parentSenseID)-example-\(index)-\(example.audioID)-\(example.hanji)-\(example.romanization)-\(example.mandarin)"
    }
}

private extension View {
    @ViewBuilder
    func detailToolbar(
        displayedEntry: DictionaryEntry?,
        bookmarkStore: (any BookmarksStoreProtocol)?,
        appLocale: AppLocale,
        isBookmarked: Bool,
        toggleBookmark: @escaping (DictionaryEntry) -> Void
    ) -> some View {
#if os(macOS)
        self
#else
        toolbar {
            if let displayedEntry {
                Button {
                    toggleBookmark(displayedEntry)
                } label: {
                    Label(
                        isBookmarked
                            ? AppLocalizer.text(.bookmarksRemove, locale: appLocale)
                            : AppLocalizer.text(.bookmarksAdd, locale: appLocale),
                        systemImage: isBookmarked ? "bookmark.fill" : "bookmark"
                    )
                }

                ShareLink(item: WordDetailViewModel.shareText(for: displayedEntry)) {
                    Label(AppLocalizer.text(.share, locale: appLocale), systemImage: "square.and.arrow.up")
                }
            }
        }
#endif
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
            Section {
                RelationshipRows(
                    words: visibleWords,
                    openableWords: openableWords,
                    openWord: openWord
                )
            } header: {
                DetailSectionHeader(title)
            }
        }
    }

    private var normalizedWords: [String] {
        words.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

private struct LinkedReferenceText: View {
    @Environment(\.locale) private var locale
    var text: String
    var openWord: (String) -> Void

    init(_ text: String, openWord: @escaping (String) -> Void) {
        self.text = text
        self.openWord = openWord
    }

    var body: some View {
        let segments = DictionaryReferenceParser.segments(from: text)
        let appLocale = AppLocalizer.appLocale(from: locale)
        RelationshipChipLayout(spacing: 2) {
            ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                switch segment {
                case .text(let value):
                    Text(value)
                case .reference(let word):
                    Button {
                        openWord(word)
                    } label: {
                        Text(AppLocalizer.formattedText(.detailLinkedReferenceFormat, locale: appLocale, word))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.tint)
                    .accessibilityLabel(word)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .taigiReadingFont(.body)
    }
}

enum DictionaryReferenceTextSegment: Equatable {
    case text(String)
    case reference(String)
}

enum DictionaryReferenceParser {
    static func segments(from text: String) -> [DictionaryReferenceTextSegment] {
        var segments: [DictionaryReferenceTextSegment] = []
        var remaining = text[...]

        while let openRange = remaining.range(of: "【"),
              let closeRange = remaining[openRange.upperBound...].range(of: "】") {
            let prefix = remaining[..<openRange.lowerBound]
            if !prefix.isEmpty {
                segments.append(.text(String(prefix)))
            }

            let word = remaining[openRange.upperBound..<closeRange.lowerBound]
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if word.isEmpty {
                segments.append(.text("【】"))
            } else {
                segments.append(.reference(word))
            }

            remaining = remaining[closeRange.upperBound...]
        }

        if !remaining.isEmpty {
            segments.append(.text(String(remaining)))
        }

        return segments.isEmpty ? [.text(text)] : segments
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
                    .taigiReadingFont(.caption)
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
        RelationshipChipLayout(spacing: 8) {
            ForEach(words, id: \.self) { word in
                RelationshipChip(
                    word: word,
                    isOpenable: openableWords.contains(word),
                    openWord: openWord
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 2)
    }
}

private struct RelationshipChip: View {
    var word: String
    var isOpenable: Bool
    var openWord: (String) -> Void

    var body: some View {
        Button {
            openWord(word)
        } label: {
            Text(word)
                .taigiReadingFont(.subheadline)
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
        .opacity(isOpenable ? 1 : 0.92)
        .accessibilityIdentifier("dictionary.relationship.\(word)")
    }
}

private struct RelationshipChipLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var measuredWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: finite(maxWidth), height: nil))
            let itemWidth = maxWidth.isFinite ? min(size.width, maxWidth) : size.width

            if currentX > 0, currentX + spacing + itemWidth > maxWidth {
                currentY += rowHeight + spacing
                currentX = 0
                rowHeight = 0
            }

            if currentX > 0 {
                currentX += spacing
            }

            currentX += itemWidth
            rowHeight = max(rowHeight, size.height)
            measuredWidth = max(measuredWidth, currentX)
        }

        return CGSize(
            width: maxWidth.isFinite ? maxWidth : measuredWidth,
            height: currentY + rowHeight
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: bounds.width, height: nil))
            let itemWidth = min(size.width, bounds.width)

            if currentX > bounds.minX, currentX + spacing + itemWidth > bounds.maxX {
                currentY += rowHeight + spacing
                currentX = bounds.minX
                rowHeight = 0
            }

            if currentX > bounds.minX {
                currentX += spacing
            }

            subview.place(
                at: CGPoint(x: currentX, y: currentY),
                proposal: ProposedViewSize(width: itemWidth, height: size.height)
            )

            currentX += itemWidth
            rowHeight = max(rowHeight, size.height)
        }
    }

    private func finite(_ value: CGFloat) -> CGFloat? {
        value.isFinite ? value : nil
    }
}

private struct DetailStringListSection: View {
    var title: String
    var values: [String]

    var body: some View {
        let visibleValues = values.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if !visibleValues.isEmpty {
            Section {
                ForEach(visibleValues, id: \.self) { value in
                    Text(value)
                        .taigiReadingFont(.body)
                }
            } header: {
                DetailSectionHeader(title)
            }
        }
    }
}

private struct DetailSectionHeader: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .taigiReadingFont(.subheadline, weight: .semibold)
            .foregroundStyle(.secondary)
            .textCase(nil)
    }
}
