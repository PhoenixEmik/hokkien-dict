import Foundation

public struct DictionarySense: Hashable, Sendable {
    public var partOfSpeech: String
    public var definition: String
    public var definitionSynonyms: [String]
    public var definitionAntonyms: [String]
    public var examples: [DictionaryExample]

    public init(
        partOfSpeech: String,
        definition: String,
        definitionSynonyms: [String] = [],
        definitionAntonyms: [String] = [],
        examples: [DictionaryExample] = []
    ) {
        self.partOfSpeech = partOfSpeech
        self.definition = definition
        self.definitionSynonyms = definitionSynonyms
        self.definitionAntonyms = definitionAntonyms
        self.examples = examples
    }
}

extension DictionarySense: Decodable {
    private enum CodingKeys: String, CodingKey {
        case partOfSpeech
        case definition
        case definitionSynonyms
        case definitionAntonyms
        case examples
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            partOfSpeech: try container.decodeIfPresent(String.self, forKey: .partOfSpeech) ?? "",
            definition: try container.decodeIfPresent(String.self, forKey: .definition) ?? "",
            definitionSynonyms: try container.decodeTrimmedStringListIfPresent(forKey: .definitionSynonyms),
            definitionAntonyms: try container.decodeTrimmedStringListIfPresent(forKey: .definitionAntonyms),
            examples: try container.decodeIfPresent([DictionaryExample].self, forKey: .examples) ?? []
        )
    }
}
