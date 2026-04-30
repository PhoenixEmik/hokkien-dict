import Foundation
import XCTest
@testable import TaigiDictCore

final class OfflineAudioStoreTests: XCTestCase {
    func testSnapshotRefreshesDownloadProgress() async {
        let storage = TestAudioStorage()
        let downloader = SequencedDownloader(snapshots: [
            DownloadSnapshot(state: .downloading, downloadedBytes: 10, totalBytes: 100),
            DownloadSnapshot(state: .downloading, downloadedBytes: 20, totalBytes: 100),
            DownloadSnapshot(state: .completed, downloadedBytes: 100, totalBytes: 100),
        ])
        let indexer = TestIndexer(indexByType: [
            .word: ["1(1)": "word/1(1).mp3"],
        ])
        let store = OfflineAudioStore(
            downloadService: downloader,
            storage: storage,
            zipIndexer: indexer
        )

        let first = await store.snapshot(for: .word)
        let second = await store.snapshot(for: .word)
        let third = await store.snapshot(for: .word)

        XCTAssertEqual(first.downloadedBytes, 10)
        XCTAssertEqual(second.downloadedBytes, 20)
        XCTAssertEqual(third.state, .completed)
        XCTAssertEqual(third.downloadedBytes, 100)
    }

    func testCompletedDownloadBuildsIndexAndSupportsPlayback() async throws {
        let storage = TestAudioStorage()
        let downloader = TestDownloader(snapshots: [
            "word": DownloadSnapshot(state: .completed, downloadedBytes: 100, totalBytes: 100),
        ])
        let indexer = TestIndexer(indexByType: [
            .word: ["1(1)": "word/1(1).mp3", "x": "word/x.mp3"],
        ])
        let playback = TestPlaybackController()

        let store = OfflineAudioStore(
            downloadService: downloader,
            storage: storage,
            zipIndexer: indexer,
            playbackService: playback
        )

        await store.startDownload(.word)
        let hasValidation = await store.hasClip("1(1)", in: .word)

        XCTAssertTrue(hasValidation)

        try await store.playClip("1(1)", from: .word)
        let playing = await store.currentlyPlayingClipID()
        XCTAssertEqual(playing, "word:1(1)")
    }

    func testMissingValidationClipMarksSnapshotFailed() async {
        let storage = TestAudioStorage()
        let downloader = TestDownloader(snapshots: [
            "sentence": DownloadSnapshot(state: .completed, downloadedBytes: 80, totalBytes: 80),
        ])
        let indexer = TestIndexer(indexByType: [
            .sentence: ["not-validation": "sentence/no.mp3"],
        ])
        let playback = TestPlaybackController()

        let store = OfflineAudioStore(
            downloadService: downloader,
            storage: storage,
            zipIndexer: indexer,
            playbackService: playback
        )

        await store.startDownload(.sentence)
        let snapshot = await store.snapshot(for: .sentence)

        switch snapshot.state {
        case .failed(let message):
            XCTAssertTrue(message.contains("missing validation clip"))
        default:
            XCTFail("Expected failed snapshot when validation clip is missing")
        }
    }

    func testSnapshotTreatsExistingValidArchiveAsCompletedWhenDownloaderIsIdle() async throws {
        let storage = TestAudioStorage()
        let archiveURL = storage.archiveURL(for: .word)
        try FileManager.default.createDirectory(
            at: archiveURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("archive".utf8).write(to: archiveURL)

        let downloader = TestDownloader(snapshots: [
            "word": DownloadSnapshot(state: .idle),
        ])
        let indexer = TestIndexer(indexByType: [
            .word: ["1(1)": "word/1(1).mp3"],
        ])
        let store = OfflineAudioStore(
            downloadService: downloader,
            storage: storage,
            zipIndexer: indexer
        )

        let snapshot = await store.snapshot(for: .word)

        XCTAssertEqual(snapshot.state, .completed)
        XCTAssertGreaterThan(snapshot.downloadedBytes, 0)
        XCTAssertEqual(snapshot.downloadedBytes, snapshot.totalBytes)
    }
}

private actor SequencedDownloader: ResumableDownloading {
    private var snapshots: [DownloadSnapshot]
    private var index = 0

    init(snapshots: [DownloadSnapshot]) {
        self.snapshots = snapshots
    }

    func startDownload(id: String, from remoteURL: URL, to localURL: URL) async {}
    func pauseDownload(id: String) async {}
    func resumeDownload(id: String) async {}
    func restartDownload(id: String, from remoteURL: URL, to localURL: URL) async {
        index = 0
    }

    func snapshot(for id: String) async -> DownloadSnapshot {
        guard !snapshots.isEmpty else {
            return DownloadSnapshot()
        }

        let snapshot = snapshots[min(index, snapshots.count - 1)]
        index += 1
        return snapshot
    }
}

private struct TestAudioStorage: AudioArchiveStoring {
    let root = FileManager.default.temporaryDirectory
        .appendingPathComponent("OfflineAudioStoreTests-\(UUID().uuidString)", isDirectory: true)

    func archiveURL(for type: AudioArchiveType) -> URL {
        root.appendingPathComponent("\(type.rawValue).zip")
    }

    func clipCacheURL(for type: AudioArchiveType, clipID: String) -> URL {
        root.appendingPathComponent("\(type.rawValue)-\(clipID).mp3")
    }

    func clearClipCache(for type: AudioArchiveType) throws {}
}

private actor TestDownloader: ResumableDownloading {
    private var snapshotsByID: [String: DownloadSnapshot]

    init(snapshots: [String: DownloadSnapshot]) {
        self.snapshotsByID = snapshots
    }

    func startDownload(id: String, from remoteURL: URL, to localURL: URL) async {}
    func pauseDownload(id: String) async {}
    func resumeDownload(id: String) async {}
    func restartDownload(id: String, from remoteURL: URL, to localURL: URL) async {}

    func snapshot(for id: String) async -> DownloadSnapshot {
        snapshotsByID[id] ?? DownloadSnapshot()
    }
}

private struct TestIndexer: AudioZipIndexing {
    var indexByType: [AudioArchiveType: [String: String]]

    func buildIndex(for archiveURL: URL) throws -> [String: String] {
        if archiveURL.lastPathComponent.contains("word") {
            return indexByType[.word] ?? [:]
        }
        return indexByType[.sentence] ?? [:]
    }

    func materializeClip(clipID: String, from archiveURL: URL, index: [String: String], to clipURL: URL) throws {
        guard index[clipID] != nil else {
            throw AudioZipIndexError.clipNotFound(clipID)
        }

        let parent = clipURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        try Data("clip-\(clipID)".utf8).write(to: clipURL)
    }
}

private actor TestPlaybackController: AudioPlaybackControlling {
    private var currentClip: String?

    func play(clipURL: URL, clipID: String) async throws {
        currentClip = clipID
    }

    func stop() async {
        currentClip = nil
    }

    func currentlyPlayingClipID() async -> String? {
        currentClip
    }
}
