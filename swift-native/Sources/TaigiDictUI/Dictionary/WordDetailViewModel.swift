import Foundation
import Observation
import TaigiDictCore

@MainActor
@Observable
public final class WordDetailViewModel {
    public private(set) var entry: DictionaryEntry?
    public private(set) var resolvedEntryID: Int64?
    public private(set) var openableWords: Set<String> = []
    public private(set) var errorMessage: String?
    public private(set) var audioMessage: String?

    private let library: DictionaryLibrary
    private let offlineAudioStore: (any OfflineAudioManaging)?
    private let conversionService: (any ChineseConversionProviding)?
    private var localizedOpenableWordMap: [String: String] = [:]
    private var appLocale: AppLocale = .traditionalChinese

    public init(
        library: DictionaryLibrary,
        offlineAudioStore: (any OfflineAudioManaging)? = nil,
        conversionService: (any ChineseConversionProviding)? = nil
    ) {
        self.library = library
        self.offlineAudioStore = offlineAudioStore
        self.conversionService = conversionService
    }

    public func prepare(
        entry sourceEntry: DictionaryEntry,
        locale: AppLocale = .traditionalChinese
    ) async {
        appLocale = locale
        errorMessage = nil
        entry = sourceEntry
        resolvedEntryID = sourceEntry.id
        openableWords = []
        localizedOpenableWordMap = [:]
        audioMessage = nil

        do {
            let resolvedEntry = try await resolveAliasChain(from: sourceEntry)
            entry = await DictionaryDisplayLocalization.translateEntry(
                resolvedEntry,
                locale: locale,
                converter: conversionService
            )
            resolvedEntryID = resolvedEntry.id
            let openableWordsResult = try await resolveOpenableWords(from: resolvedEntry, locale: locale)
            openableWords = openableWordsResult.words
            localizedOpenableWordMap = openableWordsResult.wordMap
        } catch {
            entry = sourceEntry
            resolvedEntryID = sourceEntry.id
            errorMessage = String(describing: error)
        }
    }

    public func linkedEntry(
        for word: String,
        locale: AppLocale = .traditionalChinese
    ) async -> DictionaryEntry? {
        guard openableWords.contains(word) else {
            return nil
        }

        let sourceWord = localizedOpenableWordMap[word] ?? word
        let normalizedWord = await DictionaryDisplayLocalization.normalizeLookupWord(
            sourceWord,
            locale: locale,
            converter: conversionService
        )
        return try? await library.findLinkedEntry(normalizedWord)
    }

    public func shareText() -> String {
        guard let entry else {
            return ""
        }

        var lines = [
            entry.hanji,
            entry.romanization,
        ].filter { !$0.isEmpty }

        if let definition = entry.senses.first(where: { !$0.definition.isEmpty })?.definition {
            lines.append(definition)
        } else if !entry.briefSummary.isEmpty {
            lines.append(entry.briefSummary)
        }

        return lines.joined(separator: "\n")
    }

    public func playWordAudio() async {
        guard let entry else {
            return
        }

        await playAudioClip(entry.audioID, archiveType: .word)
    }

    public func playExampleAudio(_ example: DictionaryExample) async {
        await playAudioClip(example.audioID, archiveType: .sentence)
    }

    private func playAudioClip(_ clipID: String, archiveType: AudioArchiveType) async {
        let normalized = clipID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            audioMessage = AppLocalizer.text(.noAudioAvailable, locale: appLocale)
            return
        }

        guard let offlineAudioStore else {
            audioMessage = AppLocalizer.text(.audioNotInitialized, locale: appLocale)
            return
        }

        do {
            try await offlineAudioStore.playClip(normalized, from: archiveType)
            let expectedClipID = "\(archiveType.rawValue):\(normalized)"
            if await offlineAudioStore.currentlyPlayingClipID() == expectedClipID {
                audioMessage = AppLocalizer.text(.audioPlaying, locale: appLocale)
            } else {
                audioMessage = AppLocalizer.text(.audioStopped, locale: appLocale)
            }
        } catch {
            audioMessage = userFriendlyAudioErrorMessage(error)
        }
    }

    private func userFriendlyAudioErrorMessage(_ error: Error) -> String {
        if let zipError = error as? AudioZipIndexError {
            switch zipError {
            case .clipNotFound:
                return AppLocalizer.text(.audioPlaybackMissingClip, locale: appLocale)
            case .invalidArchive:
                return AppLocalizer.text(.audioPlaybackArchiveBroken, locale: appLocale)
            }
        }

        return "\(AppLocalizer.text(.audioPlaybackFailedPrefix, locale: appLocale))\(error.localizedDescription)"
    }

    private func resolveAliasChain(from sourceEntry: DictionaryEntry) async throws -> DictionaryEntry {
        var currentEntry = sourceEntry
        var visitedIDs = Set<Int64>()

        while let targetID = currentEntry.aliasTargetEntryID {
            guard visitedIDs.insert(currentEntry.id).inserted else {
                break
            }

            guard let targetEntry = try await library.entry(id: targetID) else {
                break
            }

            currentEntry = targetEntry
        }

        return currentEntry
    }

    private func resolveOpenableWords(
        from entry: DictionaryEntry,
        locale: AppLocale
    ) async throws -> (words: Set<String>, wordMap: [String: String]) {
        var words = OrderedUniqueStrings()
        words.append(contentsOf: entry.variantChars)
        words.append(contentsOf: entry.wordSynonyms)
        words.append(contentsOf: entry.wordAntonyms)

        for sense in entry.senses {
            words.append(contentsOf: sense.definitionSynonyms)
            words.append(contentsOf: sense.definitionAntonyms)
        }

        var openable = Set<String>()
        var wordMap: [String: String] = [:]
        for word in words.values {
            guard let linkedEntry = try await library.findLinkedEntry(word) else {
                continue
            }

            if linkedEntry.id != entry.id, hasDisplayableSense(linkedEntry) {
                let displayWord = await DictionaryDisplayLocalization.translateEntryWord(
                    word,
                    locale: locale,
                    converter: conversionService
                )
                openable.insert(displayWord)
                wordMap[displayWord] = word
            }
        }

        return (openable, wordMap)
    }

    private func hasDisplayableSense(_ entry: DictionaryEntry) -> Bool {
        entry.senses.contains { sense in
            !sense.partOfSpeech.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || !sense.definition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || !sense.examples.isEmpty
        }
    }
}

private struct OrderedUniqueStrings {
    private(set) var values: [String] = []
    private var seen = Set<String>()

    mutating func append(contentsOf newValues: [String]) {
        for value in newValues {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, seen.insert(trimmed).inserted else {
                continue
            }
            values.append(trimmed)
        }
    }
}
