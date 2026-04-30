import Foundation

public actor InstalledDictionaryRepository: DictionaryRepositoryProtocol {
    private let sourceDirectory: URL
    private let installedDirectory: URL
    private let fileManager: FileManager
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let importService: DictionaryImportService
    private let repository: SQLiteDictionaryRepository

    public init(
        sourceDirectory: URL,
        installedDirectory: URL,
        fileManager: FileManager = .default,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder(),
        importService: DictionaryImportService = DictionaryImportService()
    ) {
        self.sourceDirectory = sourceDirectory
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
        try await prepareInstalledPackage()
        return try await repository.loadBundle()
    }

    public func search(
        _ rawQuery: String,
        limit: Int = DictionarySearchService.defaultLimit,
        offset: Int = 0
    ) async throws -> [DictionaryEntry] {
        try await prepareInstalledPackage()
        return try await repository.search(rawQuery, limit: limit, offset: offset)
    }

    public func findLinkedEntry(_ rawWord: String) async throws -> DictionaryEntry? {
        try await prepareInstalledPackage()
        return try await repository.findLinkedEntry(rawWord)
    }

    public func entries(ids: [Int64]) async throws -> [DictionaryEntry] {
        try await prepareInstalledPackage()
        return try await repository.entries(ids: ids)
    }

    public func entry(id: Int64) async throws -> DictionaryEntry? {
        try await prepareInstalledPackage()
        return try await repository.entry(id: id)
    }

    public func clearBundleCache() async {
        await repository.clearBundleCache()
    }

    public func supportsLocalMaintenance() async -> Bool {
        true
    }

    public func rebuildInstalledDatabase() async throws {
        let sourceManifestURL = sourceDirectory.appendingPathComponent("dictionary_manifest.json")
        let sourceManifest = try loadManifest(at: sourceManifestURL)
        try installFromSource(manifest: sourceManifest)
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

    private func prepareInstalledPackage() async throws {
        let sourceManifestURL = sourceDirectory.appendingPathComponent("dictionary_manifest.json")

        if fileManager.fileExists(atPath: sourceManifestURL.path) {
            let sourceManifest = try loadManifest(at: sourceManifestURL)
            let sourceEntriesURL = sourceDirectory.appendingPathComponent(sourceManifest.entriesFileName)
            guard fileManager.fileExists(atPath: sourceEntriesURL.path) else {
                throw DictionaryPackageLoaderError.missingEntries(sourceEntriesURL)
            }

            if try installedPackageMatchesSource(sourceManifest) {
                return
            }

            try installFromSource(manifest: sourceManifest)
            await repository.clearBundleCache()
            return
        }

        guard try installedPackageExists() else {
            throw DictionaryPackageLoaderError.missingManifest(sourceManifestURL)
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

    private func installFromSource(manifest: DictionaryManifest) throws {
        let sourceEntriesURL = sourceDirectory.appendingPathComponent(manifest.entriesFileName)
        guard fileManager.fileExists(atPath: sourceEntriesURL.path) else {
            throw DictionaryPackageLoaderError.missingEntries(sourceEntriesURL)
        }

        try fileManager.createDirectory(at: installedDirectory, withIntermediateDirectories: true)
        let entriesData = try Data(contentsOf: sourceEntriesURL)
        _ = try importService.importDatabase(
            manifest: manifest,
            entriesData: entriesData,
            databaseURL: databaseURL
        )
        try encoder.encode(manifest).write(to: installedManifestURL, options: .atomic)
    }

    private var installedManifestURL: URL {
        installedDirectory.appendingPathComponent("dictionary_manifest.json")
    }

    private var databaseURL: URL {
        installedDirectory.appendingPathComponent("dictionary.sqlite")
    }
}