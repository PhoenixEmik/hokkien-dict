import Foundation
import XCTest
@testable import TaigiDictCore

final class TaigiDictAppStorageTests: XCTestCase {
    func testInitializesExpectedSubdirectoriesUnderTaigiDictRoot() {
        let applicationSupportDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("TaigiDictAppStorageTests-\(UUID().uuidString)", isDirectory: true)
        let storage = TaigiDictAppStorage(applicationSupportDirectory: applicationSupportDirectory)

        XCTAssertEqual(
            storage.rootDirectory,
            applicationSupportDirectory.appendingPathComponent("TaigiDict", isDirectory: true)
        )
        XCTAssertEqual(
            storage.dictionarySourceDirectory,
            applicationSupportDirectory
                .appendingPathComponent("TaigiDict", isDirectory: true)
                .appendingPathComponent("DictionarySource", isDirectory: true)
        )
        XCTAssertEqual(
            storage.installedDictionaryDirectory,
            applicationSupportDirectory
                .appendingPathComponent("TaigiDict", isDirectory: true)
                .appendingPathComponent("Dictionary", isDirectory: true)
        )
        XCTAssertEqual(
            storage.audioDirectory,
            applicationSupportDirectory
                .appendingPathComponent("TaigiDict", isDirectory: true)
                .appendingPathComponent("Audio", isDirectory: true)
        )
    }

    func testPrepareAudioDirectoryCreatesNewAudioDirectoryWhenMissing() throws {
        let fileManager = FileManager()
        let applicationSupportDirectory = makeTemporaryDirectory(fileManager: fileManager)
        defer { try? fileManager.removeItem(at: applicationSupportDirectory) }

        let storage = TaigiDictAppStorage(applicationSupportDirectory: applicationSupportDirectory)
        try storage.prepareAudioDirectory(fileManager: fileManager)

        var isDirectory: ObjCBool = false
        XCTAssertTrue(fileManager.fileExists(atPath: storage.audioDirectory.path, isDirectory: &isDirectory))
        XCTAssertTrue(isDirectory.boolValue)
    }

    func testPrepareAudioDirectoryMigratesLegacyAudioDirectory() throws {
        let fileManager = FileManager()
        let applicationSupportDirectory = makeTemporaryDirectory(fileManager: fileManager)
        defer { try? fileManager.removeItem(at: applicationSupportDirectory) }

        let legacyAudioDirectory = applicationSupportDirectory
            .appendingPathComponent("TaigiDictNative", isDirectory: true)
            .appendingPathComponent("Audio", isDirectory: true)
        try fileManager.createDirectory(at: legacyAudioDirectory, withIntermediateDirectories: true)
        let legacyArchive = legacyAudioDirectory
            .appendingPathComponent("archives", isDirectory: true)
        try fileManager.createDirectory(at: legacyArchive, withIntermediateDirectories: true)
        let legacyArchiveFile = legacyArchive.appendingPathComponent("sutiau-mp3.zip")
        try Data("audio".utf8).write(to: legacyArchiveFile)

        let storage = TaigiDictAppStorage(applicationSupportDirectory: applicationSupportDirectory)
        try storage.prepareAudioDirectory(fileManager: fileManager)

        let migratedArchiveFile = storage.audioDirectory
            .appendingPathComponent("archives", isDirectory: true)
            .appendingPathComponent("sutiau-mp3.zip")
        XCTAssertTrue(fileManager.fileExists(atPath: migratedArchiveFile.path))
        XCTAssertFalse(fileManager.fileExists(atPath: legacyAudioDirectory.path))
        XCTAssertFalse(
            fileManager.fileExists(
                atPath: applicationSupportDirectory
                    .appendingPathComponent("TaigiDictNative", isDirectory: true)
                    .path
            )
        )
    }

    func testPrepareAudioDirectoryKeepsCurrentDirectoryWhenLegacyAlsoExists() throws {
        let fileManager = FileManager()
        let applicationSupportDirectory = makeTemporaryDirectory(fileManager: fileManager)
        defer { try? fileManager.removeItem(at: applicationSupportDirectory) }

        let storage = TaigiDictAppStorage(applicationSupportDirectory: applicationSupportDirectory)
        try fileManager.createDirectory(at: storage.audioDirectory, withIntermediateDirectories: true)
        let currentArchiveFile = storage.audioDirectory
            .appendingPathComponent("archives", isDirectory: true)
            .appendingPathComponent("existing.zip")
        try fileManager.createDirectory(
            at: currentArchiveFile.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("current".utf8).write(to: currentArchiveFile)

        let legacyAudioDirectory = applicationSupportDirectory
            .appendingPathComponent("TaigiDictNative", isDirectory: true)
            .appendingPathComponent("Audio", isDirectory: true)
        try fileManager.createDirectory(at: legacyAudioDirectory, withIntermediateDirectories: true)
        let legacyArchiveFile = legacyAudioDirectory
            .appendingPathComponent("archives", isDirectory: true)
            .appendingPathComponent("legacy.zip")
        try fileManager.createDirectory(
            at: legacyArchiveFile.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Data("legacy".utf8).write(to: legacyArchiveFile)

        try storage.prepareAudioDirectory(fileManager: fileManager)

        XCTAssertTrue(fileManager.fileExists(atPath: currentArchiveFile.path))
        XCTAssertTrue(fileManager.fileExists(atPath: legacyArchiveFile.path))
    }

    private func makeTemporaryDirectory(fileManager: FileManager) -> URL {
        let directory = fileManager.temporaryDirectory
            .appendingPathComponent("TaigiDictAppStorageTests-\(UUID().uuidString)", isDirectory: true)
        try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }
}
