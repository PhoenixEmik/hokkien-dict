import Foundation

public enum DictionaryJSONLReaderError: Error, Equatable {
    case invalidUTF8
    case invalidLine(line: Int, message: String)
}

public struct DictionaryJSONLReader: Sendable {
    private let decoder: JSONDecoder

    public init(decoder: JSONDecoder = JSONDecoder()) {
        self.decoder = decoder
    }

    public func readEntries(from data: Data) throws -> [DictionaryEntry] {
        var entries: [DictionaryEntry] = []
        try enumerateEntries(from: data) { entry in
            entries.append(entry)
        }
        return entries
    }

    public func enumerateEntries(
        from data: Data,
        onEntry: (DictionaryEntry) throws -> Void
    ) throws {
        guard let content = String(data: data, encoding: .utf8) else {
            throw DictionaryJSONLReaderError.invalidUTF8
        }

        for (offset, rawLine) in content.split(whereSeparator: \.isNewline).enumerated() {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty {
                continue
            }

            guard let lineData = line.data(using: .utf8) else {
                throw DictionaryJSONLReaderError.invalidUTF8
            }

            do {
                try onEntry(try decoder.decode(DictionaryEntry.self, from: lineData))
            } catch let error as DictionaryJSONLReaderError {
                throw error
            } catch {
                throw DictionaryJSONLReaderError.invalidLine(
                    line: offset + 1,
                    message: String(describing: error)
                )
            }
        }
    }
}
