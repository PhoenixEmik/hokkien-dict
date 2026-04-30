import Foundation
import XCTest
import ZIPFoundation
@testable import TaigiDictCore

final class AudioZipIndexServiceTests: XCTestCase {
    func testBuildIndexAndMaterializeClip() throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AudioZipIndexServiceTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: temporaryDirectory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporaryDirectory) }

        let archiveURL = temporaryDirectory.appendingPathComponent("sample.zip")
        let clipURL = temporaryDirectory.appendingPathComponent("clips/1(1).mp3")

        try createArchive(at: archiveURL, entries: [
            "word/1(1).mp3": Data("word-audio".utf8),
            "word/ignored.txt": Data("ignored".utf8),
        ])

        let service = AudioZipIndexService()
        let index = try service.buildIndex(for: archiveURL)

        XCTAssertEqual(index["1(1)"], "word/1(1).mp3")

        try service.materializeClip(clipID: "1(1)", from: archiveURL, index: index, to: clipURL)
        let extracted = try Data(contentsOf: clipURL)
        XCTAssertEqual(extracted, Data("word-audio".utf8))
    }

    private func createArchive(at url: URL, entries: [String: Data]) throws {
        guard let archive = Archive(url: url, accessMode: .create) else {
            throw NSError(domain: "AudioZipIndexServiceTests", code: 1)
        }

        for (path, data) in entries {
            try archive.addEntry(
                with: path,
                type: .file,
                uncompressedSize: UInt32(data.count),
                compressionMethod: .deflate,
                provider: { position, size in
                    let lower = Int(position)
                    let upper = lower + size
                    return data.subdata(in: lower..<upper)
                }
            )
        }
    }
}
