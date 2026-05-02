import Foundation

public struct DictionaryExample: Hashable, Sendable {
    public var hanji: String
    public var romanization: String
    public var mandarin: String
    public var audioID: String

    public init(
        hanji: String,
        romanization: String,
        mandarin: String,
        audioID: String
    ) {
        self.hanji = hanji
        self.romanization = romanization
        self.mandarin = mandarin
        self.audioID = audioID
    }
}

extension DictionaryExample: Decodable {
    private enum CodingKeys: String, CodingKey {
        case hanji
        case romanization
        case mandarin
        case audio
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            hanji: try container.decodeIfPresent(String.self, forKey: .hanji) ?? "",
            romanization: try container.decodeIfPresent(String.self, forKey: .romanization) ?? "",
            mandarin: try container.decodeIfPresent(String.self, forKey: .mandarin) ?? "",
            audioID: try container.decodeIfPresent(String.self, forKey: .audio) ?? ""
        )
    }
}
