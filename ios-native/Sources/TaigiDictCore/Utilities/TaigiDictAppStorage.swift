import Foundation

public struct TaigiDictAppStorage: Sendable, Equatable {
    public let applicationSupportDirectory: URL
    public let rootDirectory: URL
    public let dictionarySourceDirectory: URL
    public let installedDictionaryDirectory: URL
    public let audioDirectory: URL

    private let legacyAudioRootDirectory: URL

    public init(applicationSupportDirectory: URL) {
        self.applicationSupportDirectory = applicationSupportDirectory
        rootDirectory = applicationSupportDirectory
            .appendingPathComponent("TaigiDict", isDirectory: true)
        dictionarySourceDirectory = rootDirectory
            .appendingPathComponent("DictionarySource", isDirectory: true)
        installedDictionaryDirectory = rootDirectory
            .appendingPathComponent("Dictionary", isDirectory: true)
        audioDirectory = rootDirectory
            .appendingPathComponent("Audio", isDirectory: true)
        legacyAudioRootDirectory = applicationSupportDirectory
            .appendingPathComponent("TaigiDictNative", isDirectory: true)
            .appendingPathComponent("Audio", isDirectory: true)
    }

    public static func resolve(fileManager: FileManager = .default) -> TaigiDictAppStorage {
        let applicationSupportDirectory = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? fileManager.temporaryDirectory

        return TaigiDictAppStorage(applicationSupportDirectory: applicationSupportDirectory)
    }

    public func prepareAudioDirectory(fileManager: FileManager = .default) throws {
        try migrateLegacyAudioDirectoryIfNeeded(fileManager: fileManager)
        try fileManager.createDirectory(at: audioDirectory, withIntermediateDirectories: true)
    }

    public func migrateLegacyAudioDirectoryIfNeeded(fileManager: FileManager = .default) throws {
        guard fileManager.fileExists(atPath: legacyAudioRootDirectory.path) else {
            return
        }

        guard !fileManager.fileExists(atPath: audioDirectory.path) else {
            return
        }

        try fileManager.createDirectory(at: rootDirectory, withIntermediateDirectories: true)
        try fileManager.moveItem(at: legacyAudioRootDirectory, to: audioDirectory)
        try removeLegacyAudioContainerIfEmpty(fileManager: fileManager)
    }

    private func removeLegacyAudioContainerIfEmpty(fileManager: FileManager) throws {
        let legacyContainerDirectory = applicationSupportDirectory
            .appendingPathComponent("TaigiDictNative", isDirectory: true)

        guard fileManager.fileExists(atPath: legacyContainerDirectory.path) else {
            return
        }

        let remainingEntries = try fileManager.contentsOfDirectory(
            at: legacyContainerDirectory,
            includingPropertiesForKeys: nil
        )
        if remainingEntries.isEmpty {
            try fileManager.removeItem(at: legacyContainerDirectory)
        }
    }
}
