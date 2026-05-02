import Foundation

public struct DictionaryBundle: Sendable {
    public var entryCount: Int
    public var senseCount: Int
    public var exampleCount: Int
    public var entries: [DictionaryEntry]
    public var databasePath: String?

    public init(
        entryCount: Int,
        senseCount: Int,
        exampleCount: Int,
        entries: [DictionaryEntry],
        databasePath: String? = nil
    ) {
        self.entryCount = entryCount
        self.senseCount = senseCount
        self.exampleCount = exampleCount
        self.entries = entries
        self.databasePath = databasePath
    }

    public var isDatabaseBacked: Bool {
        databasePath != nil
    }
}

extension DictionaryBundle: Decodable {
    private enum CodingKeys: String, CodingKey {
        case entryCount
        case senseCount
        case exampleCount
        case entries
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let entries = try container.decode([DictionaryEntry].self, forKey: .entries)
        self.init(
            entryCount: try container.decode(Int.self, forKey: .entryCount),
            senseCount: try container.decode(Int.self, forKey: .senseCount),
            exampleCount: try container.decode(Int.self, forKey: .exampleCount),
            entries: entries
        )
    }
}
