import Foundation
import ZIPFoundation

public protocol AudioZipIndexing: Sendable {
    func buildIndex(for archiveURL: URL) throws -> [String: String]
    func materializeClip(clipID: String, from archiveURL: URL, index: [String: String], to clipURL: URL) throws
}

public struct AudioZipIndexService: AudioZipIndexing {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    public func buildIndex(for archiveURL: URL) throws -> [String: String] {
        guard let archive = Archive(url: archiveURL, accessMode: .read) else {
            throw AudioZipIndexError.invalidArchive
        }

        var index: [String: String] = [:]
        for entry in archive {
            guard entry.type == .file, entry.path.lowercased().hasSuffix(".mp3") else {
                continue
            }

            let clipID = clipIDFromPath(entry.path)
            if !clipID.isEmpty {
                index[clipID] = entry.path
            }
        }

        return index
    }

    public func materializeClip(clipID: String, from archiveURL: URL, index: [String: String], to clipURL: URL) throws {
        guard let entryPath = index[clipID] else {
            throw AudioZipIndexError.clipNotFound(clipID)
        }

        guard let archive = Archive(url: archiveURL, accessMode: .read) else {
            throw AudioZipIndexError.invalidArchive
        }

        guard let entry = archive[entryPath] else {
            throw AudioZipIndexError.clipNotFound(clipID)
        }

        let parent = clipURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: parent, withIntermediateDirectories: true)

        if fileManager.fileExists(atPath: clipURL.path) {
            try fileManager.removeItem(at: clipURL)
        }

        _ = try archive.extract(entry, to: clipURL)
    }

    private func clipIDFromPath(_ path: String) -> String {
        let fileName = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
        return fileName.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

public enum AudioZipIndexError: Error, Equatable {
    case invalidArchive
    case clipNotFound(String)
}
