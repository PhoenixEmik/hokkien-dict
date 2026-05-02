import Foundation

public struct DictionaryEntry: Identifiable, Hashable, Sendable {
    public var id: Int64
    public var type: String
    public var hanji: String
    public var romanization: String
    public var category: String
    public var audioID: String
    public var hokkienSearch: String
    public var mandarinSearch: String
    public var variantChars: [String]
    public var wordSynonyms: [String]
    public var wordAntonyms: [String]
    public var alternativePronunciations: [String]
    public var contractedPronunciations: [String]
    public var colloquialPronunciations: [String]
    public var phoneticDifferences: [String]
    public var vocabularyComparisons: [String]
    public var aliasTargetEntryID: Int64?
    public var senses: [DictionarySense]

    public init(
        id: Int64,
        type: String,
        hanji: String,
        romanization: String,
        category: String,
        audioID: String,
        hokkienSearch: String,
        mandarinSearch: String,
        variantChars: [String] = [],
        wordSynonyms: [String] = [],
        wordAntonyms: [String] = [],
        alternativePronunciations: [String] = [],
        contractedPronunciations: [String] = [],
        colloquialPronunciations: [String] = [],
        phoneticDifferences: [String] = [],
        vocabularyComparisons: [String] = [],
        aliasTargetEntryID: Int64? = nil,
        senses: [DictionarySense] = []
    ) {
        self.id = id
        self.type = type
        self.hanji = hanji
        self.romanization = romanization
        self.category = category
        self.audioID = audioID
        self.hokkienSearch = hokkienSearch
        self.mandarinSearch = mandarinSearch
        self.variantChars = variantChars
        self.wordSynonyms = wordSynonyms
        self.wordAntonyms = wordAntonyms
        self.alternativePronunciations = alternativePronunciations
        self.contractedPronunciations = contractedPronunciations
        self.colloquialPronunciations = colloquialPronunciations
        self.phoneticDifferences = phoneticDifferences
        self.vocabularyComparisons = vocabularyComparisons
        self.aliasTargetEntryID = aliasTargetEntryID
        self.senses = senses
    }

    public var redirectsToPrimaryEntry: Bool {
        aliasTargetEntryID != nil
    }

    public var briefSummary: String {
        if redirectsToPrimaryEntry {
            return ""
        }

        if let definition = senses.first(where: { !$0.definition.isEmpty })?.definition {
            return definition
        }

        if !category.isEmpty {
            return category
        }

        if !type.isEmpty {
            return type
        }

        return romanization
    }
}

extension DictionaryEntry: Decodable {
    private enum CodingKeys: String, CodingKey {
        case id
        case type
        case hanji
        case romanization
        case category
        case audio
        case hokkienSearch
        case mandarinSearch
        case variantChars
        case wordSynonyms
        case wordAntonyms
        case alternativePronunciations
        case contractedPronunciations
        case colloquialPronunciations
        case phoneticDifferences
        case vocabularyComparisons
        case aliasTargetEntryID = "aliasTargetEntryId"
        case senses
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(Int64.self, forKey: .id),
            type: try container.decodeIfPresent(String.self, forKey: .type) ?? "",
            hanji: try container.decodeIfPresent(String.self, forKey: .hanji) ?? "",
            romanization: try container.decodeIfPresent(String.self, forKey: .romanization) ?? "",
            category: try container.decodeIfPresent(String.self, forKey: .category) ?? "",
            audioID: try container.decodeIfPresent(String.self, forKey: .audio) ?? "",
            hokkienSearch: try container.decodeIfPresent(String.self, forKey: .hokkienSearch) ?? "",
            mandarinSearch: try container.decodeIfPresent(String.self, forKey: .mandarinSearch) ?? "",
            variantChars: try container.decodeTrimmedStringListIfPresent(forKey: .variantChars),
            wordSynonyms: try container.decodeTrimmedStringListIfPresent(forKey: .wordSynonyms),
            wordAntonyms: try container.decodeTrimmedStringListIfPresent(forKey: .wordAntonyms),
            alternativePronunciations: try container.decodeTrimmedStringListIfPresent(forKey: .alternativePronunciations),
            contractedPronunciations: try container.decodeTrimmedStringListIfPresent(forKey: .contractedPronunciations),
            colloquialPronunciations: try container.decodeTrimmedStringListIfPresent(forKey: .colloquialPronunciations),
            phoneticDifferences: try container.decodeTrimmedStringListIfPresent(forKey: .phoneticDifferences),
            vocabularyComparisons: try container.decodeTrimmedStringListIfPresent(forKey: .vocabularyComparisons),
            aliasTargetEntryID: try container.decodeIfPresent(Int64.self, forKey: .aliasTargetEntryID),
            senses: try container.decodeIfPresent([DictionarySense].self, forKey: .senses) ?? []
        )
    }
}

extension KeyedDecodingContainer {
    func decodeTrimmedStringListIfPresent(forKey key: Key) throws -> [String] {
        guard contains(key) else {
            return []
        }

        let values = try decode([LossyStringValue].self, forKey: key)
        return values
            .map(\.value)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}

private struct LossyStringValue: Decodable {
    var value: String

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            value = ""
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = String(int)
        } else if let double = try? container.decode(Double.self) {
            value = String(double)
        } else if let bool = try? container.decode(Bool.self) {
            value = String(bool)
        } else {
            value = ""
        }
    }
}
