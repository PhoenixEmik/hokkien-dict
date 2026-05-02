import Foundation

public protocol DictionarySourceResourceManaging: Sendable {
    func snapshot() async -> DownloadSnapshot
    func restoreBundledSource() async
    func downloadSource() async
}

public actor DictionarySourceResourceStore: DictionarySourceResourceManaging {
    private let bundledDirectory: URL?
    private let localDirectory: URL
    private let remoteBaseURL: URL
    private let fileManager: FileManager
    private let decoder: JSONDecoder
    private let session: URLSession

    private var currentSnapshot = DownloadSnapshot()

    public init(
        bundledDirectory: URL?,
        localDirectory: URL,
        remoteBaseURL: URL = URL(string: "https://app.taigidict.org/assets/")!,
        fileManager: FileManager = .default,
        decoder: JSONDecoder = JSONDecoder(),
        session: URLSession = .shared
    ) {
        self.bundledDirectory = bundledDirectory
        self.localDirectory = localDirectory
        self.remoteBaseURL = remoteBaseURL
        self.fileManager = fileManager
        self.decoder = decoder
        self.session = session
    }

    public func snapshot() async -> DownloadSnapshot {
        if case .downloading = currentSnapshot.state {
            return currentSnapshot
        }

        currentSnapshot = localPackageSnapshot()
        return currentSnapshot
    }

    public func restoreBundledSource() async {
        guard let bundledDirectory else {
            currentSnapshot = DownloadSnapshot(state: .failed("Bundled dictionary source is unavailable."))
            return
        }

        do {
            currentSnapshot = DownloadSnapshot(state: .downloading, downloadedBytes: 0, totalBytes: bundledPackageSize())
            try copyPackage(from: bundledDirectory, to: localDirectory)
            currentSnapshot = localPackageSnapshot()
        } catch {
            currentSnapshot = DownloadSnapshot(state: .failed(error.localizedDescription))
        }
    }

    public func downloadSource() async {
        do {
            currentSnapshot = DownloadSnapshot(state: .downloading, downloadedBytes: 0, totalBytes: nil)
            try fileManager.createDirectory(at: localDirectory, withIntermediateDirectories: true)

            let manifestURL = remoteBaseURL.appendingPathComponent("dictionary_manifest.json")
            let (manifestData, _) = try await session.data(from: manifestURL)
            let manifest = try decoder.decode(DictionaryManifest.self, from: manifestData)
            let entriesURL = remoteBaseURL.appendingPathComponent(manifest.entriesFileName)
            let (entriesData, response) = try await session.data(from: entriesURL)

            let totalBytes = Int64(manifestData.count + entriesData.count)
            currentSnapshot = DownloadSnapshot(
                state: .downloading,
                downloadedBytes: totalBytes,
                totalBytes: response.expectedContentLength > 0
                    ? Int64(manifestData.count) + response.expectedContentLength
                    : totalBytes
            )

            try manifestData.write(to: localManifestURL, options: .atomic)
            try entriesData.write(to: localDirectory.appendingPathComponent(manifest.entriesFileName), options: .atomic)
            currentSnapshot = localPackageSnapshot()
        } catch {
            currentSnapshot = DownloadSnapshot(
                state: .failed(error.localizedDescription),
                downloadedBytes: currentSnapshot.downloadedBytes,
                totalBytes: currentSnapshot.totalBytes
            )
        }
    }

    public func restoreBundledSourceIfNeeded() async throws {
        guard !localPackageExists() else {
            return
        }
        guard let bundledDirectory else {
            return
        }
        try copyPackage(from: bundledDirectory, to: localDirectory)
        currentSnapshot = localPackageSnapshot()
    }

    private func copyPackage(from sourceDirectory: URL, to destinationDirectory: URL) throws {
        let sourceManifestURL = sourceDirectory.appendingPathComponent("dictionary_manifest.json")
        let manifestData = try Data(contentsOf: sourceManifestURL)
        let manifest = try decoder.decode(DictionaryManifest.self, from: manifestData)
        let sourceEntriesURL = sourceDirectory.appendingPathComponent(manifest.entriesFileName)

        guard fileManager.fileExists(atPath: sourceEntriesURL.path) else {
            throw DictionaryPackageLoaderError.missingEntries(sourceEntriesURL)
        }

        try fileManager.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)
        try manifestData.write(to: destinationDirectory.appendingPathComponent("dictionary_manifest.json"), options: .atomic)
        try fileManager.copyReplacingItem(
            at: sourceEntriesURL,
            to: destinationDirectory.appendingPathComponent(manifest.entriesFileName)
        )
    }

    private func localPackageSnapshot() -> DownloadSnapshot {
        guard localPackageExists() else {
            return DownloadSnapshot(state: .idle)
        }
        let totalBytes = localPackageSize()
        return DownloadSnapshot(state: .completed, downloadedBytes: totalBytes, totalBytes: totalBytes)
    }

    private func localPackageExists() -> Bool {
        guard
            fileManager.fileExists(atPath: localManifestURL.path),
            let manifest = try? decoder.decode(DictionaryManifest.self, from: Data(contentsOf: localManifestURL))
        else {
            return false
        }

        return fileManager.fileExists(
            atPath: localDirectory.appendingPathComponent(manifest.entriesFileName).path
        )
    }

    private func localPackageSize() -> Int64 {
        packageSize(in: localDirectory)
    }

    private func bundledPackageSize() -> Int64? {
        guard let bundledDirectory else {
            return nil
        }
        return packageSize(in: bundledDirectory)
    }

    private func packageSize(in directory: URL) -> Int64 {
        let manifestURL = directory.appendingPathComponent("dictionary_manifest.json")
        guard
            let manifest = try? decoder.decode(DictionaryManifest.self, from: Data(contentsOf: manifestURL))
        else {
            return fileSize(at: manifestURL)
        }

        return fileSize(at: manifestURL) + fileSize(at: directory.appendingPathComponent(manifest.entriesFileName))
    }

    private func fileSize(at url: URL) -> Int64 {
        guard
            let values = try? url.resourceValues(forKeys: [.fileSizeKey]),
            let fileSize = values.fileSize
        else {
            return 0
        }
        return Int64(fileSize)
    }

    private var localManifestURL: URL {
        localDirectory.appendingPathComponent("dictionary_manifest.json")
    }
}

private extension FileManager {
    func copyReplacingItem(at sourceURL: URL, to destinationURL: URL) throws {
        if fileExists(atPath: destinationURL.path) {
            try removeItem(at: destinationURL)
        }
        try copyItem(at: sourceURL, to: destinationURL)
    }
}
