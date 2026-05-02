import Foundation

public actor InstalledDictionaryRepository: DictionaryRepositoryProtocol {
    private let sourceDirectory: URL
    private let fallbackSourceDirectory: URL?
    private let installedDirectory: URL
    private let fileManager: FileManager
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let importService: DictionaryImportService
    private let repository: SQLiteDictionaryRepository

    public init(
        sourceDirectory: URL,
        installedDirectory: URL,
        fallbackSourceDirectory: URL? = nil,
        fileManager: FileManager = .default,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder(),
        importService: DictionaryImportService = DictionaryImportService()
    ) {
        self.sourceDirectory = sourceDirectory
        self.fallbackSourceDirectory = fallbackSourceDirectory
        self.installedDirectory = installedDirectory
        self.fileManager = fileManager
        self.decoder = decoder
        self.encoder = encoder
        self.importService = importService
        self.repository = SQLiteDictionaryRepository(
            databaseURL: installedDirectory.appendingPathComponent("dictionary.sqlite")
        )
    }

    public func loadBundle() async throws -> DictionaryBundle {
        try await loadBundle(onProgress: nil)
    }

    public func loadBundle(
        onProgress: (@Sendable (DictionaryPreparationProgress) async -> Void)?
    ) async throws -> DictionaryBundle {
        try await prepareInstalledPackage(onProgress: onProgress)
        return try await repository.loadBundle(onProgress: onProgress)
    }

    public func search(
        _ rawQuery: String,
        limit: Int = DictionarySearchService.defaultLimit,
        offset: Int = 0
    ) async throws -> [DictionaryEntry] {
        try await prepareInstalledPackage(onProgress: nil)
        return try await repository.search(rawQuery, limit: limit, offset: offset)
    }

    public func findLinkedEntry(_ rawWord: String) async throws -> DictionaryEntry? {
        try await prepareInstalledPackage(onProgress: nil)
        return try await repository.findLinkedEntry(rawWord)
    }

    public func entries(ids: [Int64]) async throws -> [DictionaryEntry] {
        try await prepareInstalledPackage(onProgress: nil)
        return try await repository.entries(ids: ids)
    }

    public func entry(id: Int64) async throws -> DictionaryEntry? {
        try await prepareInstalledPackage(onProgress: nil)
        return try await repository.entry(id: id)
    }

    public func metadata() async throws -> [String: String]? {
        try await prepareInstalledPackage(onProgress: nil)
        return try await repository.metadata()
    }

    public func clearBundleCache() async {
        await repository.clearBundleCache()
    }

    public func supportsLocalMaintenance() async -> Bool {
        true
    }

    public func rebuildInstalledDatabase() async throws {
        try restoreSourceFromFallbackIfNeeded()
        let sourceManifestURL = sourceDirectory.appendingPathComponent("dictionary_manifest.json")
        let sourceManifest = try loadManifest(at: sourceManifestURL)
        try await installFromSource(manifest: sourceManifest, onProgress: nil)
        await repository.clearBundleCache()
    }

    public func clearInstalledDatabase() async throws {
        if fileManager.fileExists(atPath: installedManifestURL.path) {
            try fileManager.removeItem(at: installedManifestURL)
        }
        if fileManager.fileExists(atPath: databaseURL.path) {
            try fileManager.removeItem(at: databaseURL)
        }
        await repository.clearBundleCache()
    }

    private func prepareInstalledPackage(
        onProgress: (@Sendable (DictionaryPreparationProgress) async -> Void)?
    ) async throws {
        try restoreSourceFromFallbackIfNeeded()
        let sourceManifestURL = sourceDirectory.appendingPathComponent("dictionary_manifest.json")

        if let onProgress {
            await onProgress(
                DictionaryPreparationProgress(
                    step: .checkingPackage,
                    fraction: 0,
                    completedUnits: 0,
                    totalUnits: 1
                )
            )
        }

        if fileManager.fileExists(atPath: sourceManifestURL.path) {
            let sourceManifest = try loadManifest(at: sourceManifestURL)
            let sourceEntriesURL = sourceDirectory.appendingPathComponent(sourceManifest.entriesFileName)
            guard fileManager.fileExists(atPath: sourceEntriesURL.path) else {
                throw DictionaryPackageLoaderError.missingEntries(sourceEntriesURL)
            }

            if try installedPackageMatchesSource(sourceManifest) {
                if let onProgress {
                    await onProgress(
                        DictionaryPreparationProgress(
                            step: .checkingPackage,
                            fraction: 1,
                            completedUnits: 1,
                            totalUnits: 1
                        )
                    )
                }
                return
            }

            if let onProgress {
                await onProgress(
                    DictionaryPreparationProgress(
                        step: .importingDatabase,
                        fraction: 0,
                        completedUnits: 0,
                        totalUnits: max(sourceManifest.entryCount, 1)
                    )
                )
            }

            try await installFromSource(manifest: sourceManifest, onProgress: onProgress)
            await repository.clearBundleCache()
            return
        }

        guard try installedPackageExists() else {
            throw DictionaryPackageLoaderError.missingManifest(sourceManifestURL)
        }

        if let onProgress {
            await onProgress(
                DictionaryPreparationProgress(
                    step: .checkingPackage,
                    fraction: 1,
                    completedUnits: 1,
                    totalUnits: 1
                )
            )
        }
    }

    private func installedPackageMatchesSource(_ sourceManifest: DictionaryManifest) throws -> Bool {
        guard fileManager.fileExists(atPath: installedManifestURL.path) else {
            return false
        }

        let installedManifest = try loadManifest(at: installedManifestURL)
        guard installedManifest == sourceManifest else {
            return false
        }

        return fileManager.fileExists(atPath: databaseURL.path)
    }

    private func installedPackageExists() throws -> Bool {
        guard fileManager.fileExists(atPath: installedManifestURL.path) else {
            return false
        }
        return fileManager.fileExists(atPath: databaseURL.path)
    }

    private func loadManifest(at url: URL) throws -> DictionaryManifest {
        try decoder.decode(DictionaryManifest.self, from: Data(contentsOf: url))
    }

    private func restoreSourceFromFallbackIfNeeded() throws {
        let sourceManifestURL = sourceDirectory.appendingPathComponent("dictionary_manifest.json")
        guard !fileManager.fileExists(atPath: sourceManifestURL.path), let fallbackSourceDirectory else {
            return
        }

        let fallbackManifestURL = fallbackSourceDirectory.appendingPathComponent("dictionary_manifest.json")
        let manifest = try loadManifest(at: fallbackManifestURL)
        let fallbackEntriesURL = fallbackSourceDirectory.appendingPathComponent(manifest.entriesFileName)
        guard fileManager.fileExists(atPath: fallbackEntriesURL.path) else {
            throw DictionaryPackageLoaderError.missingEntries(fallbackEntriesURL)
        }

        try fileManager.createDirectory(at: sourceDirectory, withIntermediateDirectories: true)
        try Data(contentsOf: fallbackManifestURL)
            .write(to: sourceManifestURL, options: .atomic)

        let sourceEntriesURL = sourceDirectory.appendingPathComponent(manifest.entriesFileName)
        if fileManager.fileExists(atPath: sourceEntriesURL.path) {
            try fileManager.removeItem(at: sourceEntriesURL)
        }
        try fileManager.copyItem(at: fallbackEntriesURL, to: sourceEntriesURL)
    }

    private func installFromSource(
        manifest: DictionaryManifest,
        onProgress: (@Sendable (DictionaryPreparationProgress) async -> Void)?
    ) async throws {
        let sourceEntriesURL = sourceDirectory.appendingPathComponent(manifest.entriesFileName)
        guard fileManager.fileExists(atPath: sourceEntriesURL.path) else {
            throw DictionaryPackageLoaderError.missingEntries(sourceEntriesURL)
        }

        try fileManager.createDirectory(at: installedDirectory, withIntermediateDirectories: true)
        let entriesData = try Data(contentsOf: sourceEntriesURL)
        _ = try importService.importDatabase(
            manifest: manifest,
            entriesData: entriesData,
            databaseURL: databaseURL,
            onProgress: { progress in
                guard let onProgress else {
                    return
                }

                Self.emitProgressSync(
                    DictionaryPreparationProgress(
                        step: .importingDatabase,
                        fraction: progress.fraction,
                        completedUnits: progress.processedEntries,
                        totalUnits: progress.totalEntries
                    ),
                    onProgress: onProgress
                )
            }
        )
        try encoder.encode(manifest).write(to: installedManifestURL, options: .atomic)
    }

    private static func emitProgressSync(
        _ progress: DictionaryPreparationProgress,
        onProgress: @escaping @Sendable (DictionaryPreparationProgress) async -> Void
    ) {
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            await onProgress(progress)
            semaphore.signal()
        }
        semaphore.wait()
    }

    private var installedManifestURL: URL {
        installedDirectory.appendingPathComponent("dictionary_manifest.json")
    }

    private var databaseURL: URL {
        installedDirectory.appendingPathComponent("dictionary.sqlite")
    }
}
