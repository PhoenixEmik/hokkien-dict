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

    func testMissingValidationClipDiscardsInvalidArchive() async throws {
        let storage = TestAudioStorage()
        let archiveURL = try writeArchive(for: .sentence, in: storage)
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

        XCTAssertEqual(snapshot.state, .idle)
        XCTAssertFalse(FileManager.default.fileExists(atPath: archiveURL.path))
    }

    func testInvalidArchiveDiscardsDamagedArchive() async throws {
        let storage = TestAudioStorage()
        let archiveURL = try writeArchive(for: .word, in: storage)
        let downloader = TestDownloader(snapshots: [
            "word": DownloadSnapshot(state: .completed, downloadedBytes: 80, totalBytes: 80),
        ])
        let store = OfflineAudioStore(
            downloadService: downloader,
            storage: storage,
            zipIndexer: FailingIndexer(error: .invalidArchive)
        )

        await store.startDownload(.word)
        let snapshot = await store.snapshot(for: .word)

        XCTAssertEqual(snapshot.state, .idle)
        XCTAssertFalse(FileManager.default.fileExists(atPath: archiveURL.path))
    }

    func testExistingInvalidArchiveIsDiscardedAfterBackgroundValidation() async throws {
        let storage = TestAudioStorage()
        let archiveURL = try writeArchive(for: .word, in: storage)

        let downloader = TestDownloader(snapshots: [
            "word": DownloadSnapshot(state: .idle),
        ])
        let store = OfflineAudioStore(
            downloadService: downloader,
            storage: storage,
            zipIndexer: FailingIndexer(error: .invalidArchive)
        )

        let first = await store.snapshot(for: .word)

        XCTAssertEqual(first.state, .completed)

        try await Task.sleep(nanoseconds: 50_000_000)
        let second = await store.snapshot(for: .word)

        XCTAssertEqual(second.state, .idle)
        XCTAssertFalse(FileManager.default.fileExists(atPath: archiveURL.path))
    }

    func testPartialArchiveIsPresentedAsPausedWhenDownloaderIsIdle() async throws {
        let storage = TestAudioStorage()
        try writePartialArchive(for: .word, in: storage, contents: "partial archive")

        let downloader = TestDownloader(snapshots: [
            "word": DownloadSnapshot(state: .idle),
        ])
        let store = OfflineAudioStore(
            downloadService: downloader,
            storage: storage,
            zipIndexer: FailingIndexer(error: .invalidArchive)
        )

        let snapshot = await store.snapshot(for: .word)

        XCTAssertEqual(snapshot.state, .paused)
        XCTAssertGreaterThan(snapshot.downloadedBytes, 0)
    }

    func testResumePartialArchiveStartsDownloadJob() async throws {
        let storage = TestAudioStorage()
        try writePartialArchive(for: .word, in: storage, contents: "partial archive")

        let downloader = TestDownloader(snapshots: [
            "word": DownloadSnapshot(state: .idle),
        ])
        let store = OfflineAudioStore(
            downloadService: downloader,
            storage: storage,
            zipIndexer: FailingIndexer(error: .invalidArchive)
        )

        await store.resumeDownload(.word)
        let startedIDs = await downloader.startDownloadIDs()
        let resumedIDs = await downloader.resumeDownloadIDs()

        XCTAssertEqual(startedIDs, ["word"])
        XCTAssertEqual(resumedIDs, [])
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

    func testExistingArchiveWithoutCurrentDictionaryMetadataRequestsUpdate() async throws {
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
            zipIndexer: indexer,
            expectedDictionaryEntriesChecksum: "current-checksum"
        )

        let snapshot = await store.snapshot(for: .word)

        XCTAssertEqual(snapshot.state, .completed)
        XCTAssertTrue(snapshot.needsDictionaryUpdate)
    }

    func testCompletedDownloadStoresCurrentDictionaryMetadata() async throws {
        let storage = TestAudioStorage()
        let downloader = TestDownloader(snapshots: [
            "word": DownloadSnapshot(state: .completed, downloadedBytes: 100, totalBytes: 100),
        ])
        let indexer = TestIndexer(indexByType: [
            .word: ["1(1)": "word/1(1).mp3"],
        ])
        let store = OfflineAudioStore(
            downloadService: downloader,
            storage: storage,
            zipIndexer: indexer,
            expectedDictionaryEntriesChecksum: "current-checksum"
        )

        await store.startDownload(.word)
        let snapshot = await store.snapshot(for: .word)

        XCTAssertEqual(snapshot.state, .completed)
        XCTAssertFalse(snapshot.needsDictionaryUpdate)
        let metadataURL = storage.archiveURL(for: .word)
            .deletingPathExtension()
            .appendingPathExtension("metadata.json")
        let metadataData = try Data(contentsOf: metadataURL)
        let metadata = try JSONSerialization.jsonObject(with: metadataData) as? [String: String]
        XCTAssertEqual(metadata?["dictionaryEntriesChecksumSHA256"], "current-checksum")
    }

    func testSnapshotReturnsExistingArchiveBeforeIndexValidationFinishes() async throws {
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
        let indexer = BlockingIndexer(index: ["1(1)": "word/1(1).mp3"])
        let store = OfflineAudioStore(
            downloadService: downloader,
            storage: storage,
            zipIndexer: indexer
        )

        let returned = expectation(description: "snapshot returned before index validation completes")
        let snapshotTask = Task {
            let snapshot = await store.snapshot(for: .word)
            XCTAssertEqual(snapshot.state, .completed)
            returned.fulfill()
        }

        await fulfillment(of: [returned], timeout: 0.2)
        indexer.release()
        await snapshotTask.value
    }
}

private func writeArchive(for type: AudioArchiveType, in storage: TestAudioStorage) throws -> URL {
    let archiveURL = storage.archiveURL(for: type)
    try FileManager.default.createDirectory(
        at: archiveURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    try Data("archive".utf8).write(to: archiveURL)
    return archiveURL
}

@discardableResult
private func writePartialArchive(
    for type: AudioArchiveType,
    in storage: TestAudioStorage,
    contents: String
) throws -> URL {
    let partialURL = storage.partialArchiveURL(for: type)
    try FileManager.default.createDirectory(
        at: partialURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )
    try Data(contents.utf8).write(to: partialURL)
    return partialURL
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
    private var startedIDs: [String] = []
    private var resumedIDs: [String] = []

    init(snapshots: [String: DownloadSnapshot]) {
        self.snapshotsByID = snapshots
    }

    func startDownload(id: String, from remoteURL: URL, to localURL: URL) async {
        startedIDs.append(id)
    }

    func pauseDownload(id: String) async {}
    func resumeDownload(id: String) async {
        resumedIDs.append(id)
    }

    func restartDownload(id: String, from remoteURL: URL, to localURL: URL) async {}

    func snapshot(for id: String) async -> DownloadSnapshot {
        snapshotsByID[id] ?? DownloadSnapshot()
    }

    func startDownloadIDs() -> [String] {
        startedIDs
    }

    func resumeDownloadIDs() -> [String] {
        resumedIDs
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

private final class BlockingIndexer: AudioZipIndexing, @unchecked Sendable {
    private let semaphore = DispatchSemaphore(value: 0)
    private let index: [String: String]

    init(index: [String: String]) {
        self.index = index
    }

    func buildIndex(for archiveURL: URL) throws -> [String: String] {
        semaphore.wait()
        return index
    }

    func release() {
        semaphore.signal()
    }

    func materializeClip(clipID: String, from archiveURL: URL, index: [String: String], to clipURL: URL) throws {}
}

private struct FailingIndexer: AudioZipIndexing {
    let error: AudioZipIndexError

    func buildIndex(for archiveURL: URL) throws -> [String: String] {
        throw error
    }

    func materializeClip(clipID: String, from archiveURL: URL, index: [String: String], to clipURL: URL) throws {
        throw error
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
