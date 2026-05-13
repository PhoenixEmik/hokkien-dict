import Foundation

final class SendableFileManagerBox: @unchecked Sendable {
    let rawValue: FileManager

    init(_ rawValue: FileManager) {
        self.rawValue = rawValue
    }
}
