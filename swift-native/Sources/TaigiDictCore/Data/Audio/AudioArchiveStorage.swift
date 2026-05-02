import Foundation

public protocol AudioArchiveStoring: Sendable {
    func archiveURL(for type: AudioArchiveType) -> URL
    func clipCacheURL(for type: AudioArchiveType, clipID: String) -> URL
    func clearClipCache(for type: AudioArchiveType) throws
}

public struct AudioArchiveStorage: AudioArchiveStoring {
    private let rootDirectory: URL
    private let fileManager: FileManager

    public init(rootDirectory: URL, fileManager: FileManager = .default) {
        self.rootDirectory = rootDirectory
        self.fileManager = fileManager
    }

    public func archiveURL(for type: AudioArchiveType) -> URL {
        rootDirectory
            .appendingPathComponent("archives", isDirectory: true)
            .appendingPathComponent(type.fileName)
    }

    public func clipCacheURL(for type: AudioArchiveType, clipID: String) -> URL {
        let safeClipID = clipID.replacingOccurrences(of: "/", with: "_")
        return rootDirectory
            .appendingPathComponent("clips", isDirectory: true)
            .appendingPathComponent(type.rawValue, isDirectory: true)
            .appendingPathComponent("\(safeClipID).mp3")
    }

    public func clearClipCache(for type: AudioArchiveType) throws {
        let cacheDirectory = rootDirectory
            .appendingPathComponent("clips", isDirectory: true)
            .appendingPathComponent(type.rawValue, isDirectory: true)
        if fileManager.fileExists(atPath: cacheDirectory.path) {
            try fileManager.removeItem(at: cacheDirectory)
        }
    }
}

extension AudioArchiveStorage {
    public func ensureDirectories() throws {
        let archiveDirectory = rootDirectory.appendingPathComponent("archives", isDirectory: true)
        let clipsDirectory = rootDirectory.appendingPathComponent("clips", isDirectory: true)

        try fileManager.createDirectory(at: archiveDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: clipsDirectory, withIntermediateDirectories: true)
    }
}
