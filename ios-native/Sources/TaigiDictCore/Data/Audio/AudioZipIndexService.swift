import Foundation
import ZIPFoundation

public protocol AudioZipIndexing: Sendable {
    func buildIndex(for archiveURL: URL) throws -> [String: String]
    func materializeClip(clipID: String, from archiveURL: URL, index: [String: String], to clipURL: URL) throws
}

public struct AudioZipIndexService: AudioZipIndexing {
    private let fileManager: SendableFileManagerBox

    public init(fileManager: FileManager = .default) {
        self.fileManager = SendableFileManagerBox(fileManager)
    }

    public func buildIndex(for archiveURL: URL) throws -> [String: String] {
        let archive: Archive
        do {
            archive = try Archive(url: archiveURL, accessMode: .read)
        } catch {
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
        let fileManager = fileManager.rawValue
        guard let entryPath = index[clipID] else {
            throw AudioZipIndexError.clipNotFound(clipID)
        }

        let archive: Archive
        do {
            archive = try Archive(url: archiveURL, accessMode: .read)
        } catch {
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

extension AudioZipIndexError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidArchive:
            return "Offline audio archive is damaged or unreadable."
        case .clipNotFound:
            return "The requested audio clip is unavailable in the offline archive."
        }
    }
}
