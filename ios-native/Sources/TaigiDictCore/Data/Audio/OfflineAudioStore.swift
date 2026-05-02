import Foundation

public actor OfflineAudioStore: OfflineAudioManaging {
    private let downloadService: any ResumableDownloading
    private let storage: any AudioArchiveStoring
    private let zipIndexer: any AudioZipIndexing
    private let playbackService: any AudioPlaybackControlling

    private var snapshots: [AudioArchiveType: DownloadSnapshot] = [:]
    private var indexes: [AudioArchiveType: [String: String]] = [:]
    private var completedValidationFailures: [AudioArchiveType: DownloadSnapshot] = [:]

    public init(
        downloadService: any ResumableDownloading = ResumableDownloadService(),
        storage: any AudioArchiveStoring,
        zipIndexer: any AudioZipIndexing = AudioZipIndexService(),
        playbackService: any AudioPlaybackControlling = AudioPlaybackService()
    ) {
        self.downloadService = downloadService
        self.storage = storage
        self.zipIndexer = zipIndexer
        self.playbackService = playbackService
    }

    public func snapshot(for type: AudioArchiveType) async -> DownloadSnapshot {
        await refreshSnapshotAndIndex(type)
        return snapshots[type] ?? DownloadSnapshot()
    }

    public func startDownload(_ type: AudioArchiveType) async {
        let archiveURL = storage.archiveURL(for: type)
        await downloadService.startDownload(id: type.rawValue, from: type.remoteURL, to: archiveURL)
        await refreshSnapshotAndIndex(type)
    }

    public func pauseDownload(_ type: AudioArchiveType) async {
        await downloadService.pauseDownload(id: type.rawValue)
        await refreshSnapshot(type)
    }

    public func resumeDownload(_ type: AudioArchiveType) async {
        await downloadService.resumeDownload(id: type.rawValue)
        await refreshSnapshotAndIndex(type)
    }

    public func restartDownload(_ type: AudioArchiveType) async {
        let archiveURL = storage.archiveURL(for: type)
        await downloadService.restartDownload(id: type.rawValue, from: type.remoteURL, to: archiveURL)
        indexes[type] = nil
        completedValidationFailures[type] = nil
        try? storage.clearClipCache(for: type)
        await refreshSnapshotAndIndex(type)
    }

    public func materializeClip(_ clipID: String, from type: AudioArchiveType) async throws -> URL {
        let clipURL = storage.clipCacheURL(for: type, clipID: clipID)
        if FileManager.default.fileExists(atPath: clipURL.path) {
            return clipURL
        }

        let index = try ensureIndex(for: type)
        let archiveURL = storage.archiveURL(for: type)
        try zipIndexer.materializeClip(clipID: clipID, from: archiveURL, index: index, to: clipURL)
        return clipURL
    }

    public func playClip(_ clipID: String, from type: AudioArchiveType) async throws {
        let clipURL = try await materializeClip(clipID, from: type)
        try await playbackService.play(clipURL: clipURL, clipID: "\(type.rawValue):\(clipID)")
    }

    public func stopPlayback() async {
        await playbackService.stop()
    }

    public func currentlyPlayingClipID() async -> String? {
        await playbackService.currentlyPlayingClipID()
    }

    public func hasClip(_ clipID: String, in type: AudioArchiveType) async -> Bool {
        guard let index = try? ensureIndex(for: type) else {
            return false
        }
        return index[clipID] != nil
    }

    private func refreshSnapshot(_ type: AudioArchiveType) async {
        snapshots[type] = await downloadService.snapshot(for: type.rawValue)
        if snapshots[type]?.state != .completed {
            completedValidationFailures[type] = nil
        }
    }

    private func refreshSnapshotAndIndex(_ type: AudioArchiveType) async {
        await refreshSnapshot(type)

        if snapshots[type]?.state == .idle,
           let localCompletedSnapshot = localArchiveSnapshot(for: type) {
            snapshots[type] = localCompletedSnapshot
        }

        guard case .completed = snapshots[type]?.state else {
            return
        }
        if let failure = completedValidationFailures[type] {
            snapshots[type] = failure
            return
        }
        guard indexes[type] == nil else {
            return
        }

        do {
            let index = try zipIndexer.buildIndex(for: storage.archiveURL(for: type))
            guard index[type.validationClipID] != nil else {
                let failure = DownloadSnapshot(
                    state: .failed("missing validation clip \(type.validationClipID)"),
                    downloadedBytes: snapshots[type]?.downloadedBytes ?? 0,
                    totalBytes: snapshots[type]?.totalBytes
                )
                completedValidationFailures[type] = failure
                snapshots[type] = failure
                return
            }

            indexes[type] = index
        } catch {
            let failure = DownloadSnapshot(
                state: .failed(error.localizedDescription),
                downloadedBytes: snapshots[type]?.downloadedBytes ?? 0,
                totalBytes: snapshots[type]?.totalBytes
            )
            completedValidationFailures[type] = failure
            snapshots[type] = failure
        }
    }

    private func localArchiveSnapshot(for type: AudioArchiveType) -> DownloadSnapshot? {
        let archiveURL = storage.archiveURL(for: type)
        guard
            let fileSize = try? archiveURL.resourceValues(forKeys: [.fileSizeKey]).fileSize,
            let bytes = Int64(exactly: fileSize),
            bytes > 0
        else {
            return nil
        }

        return DownloadSnapshot(state: .completed, downloadedBytes: bytes, totalBytes: bytes)
    }

    private func ensureIndex(for type: AudioArchiveType) throws -> [String: String] {
        if let index = indexes[type] {
            return index
        }

        let index = try zipIndexer.buildIndex(for: storage.archiveURL(for: type))
        indexes[type] = index
        return index
    }
}
