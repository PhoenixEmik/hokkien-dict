import Foundation

public enum AudioArchiveType: String, CaseIterable, Hashable, Sendable {
    case word
    case sentence

    public var fileName: String {
        switch self {
        case .word:
            return "sutiau-mp3.zip"
        case .sentence:
            return "leku-mp3.zip"
        }
    }

    public var remoteURL: URL {
        URL(string: "https://app.taigidict.org/assets/\(fileName)")!
    }

    public var validationClipID: String {
        switch self {
        case .word:
            return "1(1)"
        case .sentence:
            return "1-1-1"
        }
    }
}
