import Foundation
import XCTest
@testable import TaigiDictCore

final class ResumableDownloadServiceTests: XCTestCase {
    override class func setUp() {
        super.setUp()
        MockDownloadURLProtocol.handler = nil
        PausableDownloadURLProtocol.reset()
    }

    override class func tearDown() {
        MockDownloadURLProtocol.handler = nil
        PausableDownloadURLProtocol.reset()
        super.tearDown()
    }

    func testResumeFallsBackToFullDownloadWhenServerIgnoresRange() async throws {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
            .appendingPathComponent("ResumableDownloadServiceTests-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        let localURL = directory.appendingPathComponent("audio.zip")
        let initialData = Data("OLD".utf8)
        try initialData.write(to: temporaryDownloadURL(for: localURL))

        let expectedData = Data("NEW-DATA".utf8)
        MockDownloadURLProtocol.handler = { request in
            XCTAssertEqual(request.value(forHTTPHeaderField: "Range"), "bytes=3-")

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: [
                    "Content-Length": "\(expectedData.count)",
                ]
            )!
            return (response, expectedData)
        }

        let session = makeSession()
        let service = ResumableDownloadService(session: session, fileManager: fileManager)
        await service.resumeDownload(id: "word")
        await service.startDownload(id: "word", from: URL(string: "https://example.com/word.zip")!, to: localURL)

        for _ in 0..<80 {
            let snapshot = await service.snapshot(for: "word")
            if snapshot.state == .completed {
                break
            }
            try await Task.sleep(for: .milliseconds(25))
        }

        let snapshot = await service.snapshot(for: "word")
        XCTAssertEqual(snapshot.state, .completed)
        XCTAssertEqual(snapshot.downloadedBytes, Int64(expectedData.count))
        XCTAssertEqual(snapshot.totalBytes, Int64(expectedData.count))

        let diskData = try Data(contentsOf: localURL)
        XCTAssertEqual(diskData, expectedData)
    }

    func testResumeRestartsFullDownloadWhenServerRejectsRange() async throws {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
            .appendingPathComponent("ResumableDownloadServiceTests-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        let localURL = directory.appendingPathComponent("audio.zip")
        try Data("PARTIAL".utf8).write(to: temporaryDownloadURL(for: localURL))

        let expectedData = Data("FULL-DATA".utf8)
        let requestCount = AtomicCounter()
        MockDownloadURLProtocol.handler = { request in
            let count = requestCount.increment()
            if count == 1 {
                XCTAssertEqual(request.value(forHTTPHeaderField: "Range"), "bytes=7-")
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 403,
                    httpVersion: "HTTP/1.1",
                    headerFields: nil
                )!
                return (response, Data())
            }

            XCTAssertNil(request.value(forHTTPHeaderField: "Range"))
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: [
                    "Content-Length": "\(expectedData.count)",
                ]
            )!
            return (response, expectedData)
        }

        let service = ResumableDownloadService(session: makeSession(), fileManager: fileManager)
        await service.startDownload(id: "sentence", from: URL(string: "https://example.com/sentence.zip")!, to: localURL)

        for _ in 0..<80 {
            let snapshot = await service.snapshot(for: "sentence")
            if snapshot.state == .completed {
                break
            }
            try await Task.sleep(for: .milliseconds(25))
        }

        let snapshot = await service.snapshot(for: "sentence")
        XCTAssertEqual(snapshot.state, .completed)
        XCTAssertEqual(snapshot.downloadedBytes, Int64(expectedData.count))
        XCTAssertEqual(try Data(contentsOf: localURL), expectedData)
        XCTAssertEqual(requestCount.value, 2)
    }

    func testPauseKeepsSnapshotPausedWhenSessionReportsCancellation() async throws {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
            .appendingPathComponent("ResumableDownloadServiceTests-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        let localURL = directory.appendingPathComponent("audio.zip")
        PausableDownloadURLProtocol.reset()

        let service = ResumableDownloadService(session: makePausableSession(), fileManager: fileManager)
        await service.startDownload(id: "word", from: URL(string: "https://example.com/word.zip")!, to: localURL)

        XCTAssertEqual(PausableDownloadURLProtocol.firstChunkSent.wait(timeout: .now() + 2), .success)
        for _ in 0..<80 {
            let snapshot = await service.snapshot(for: "word")
            if snapshot.downloadedBytes > 0 {
                break
            }
            try await Task.sleep(for: .milliseconds(25))
        }

        await service.pauseDownload(id: "word")
        try await Task.sleep(for: .milliseconds(100))

        let snapshot = await service.snapshot(for: "word")
        XCTAssertEqual(snapshot.state, .paused)
        XCTAssertGreaterThan(snapshot.downloadedBytes, 0)
        XCTAssertTrue(fileManager.fileExists(atPath: temporaryDownloadURL(for: localURL).path))
        XCTAssertFalse(fileManager.fileExists(atPath: localURL.path))
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockDownloadURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    private func makePausableSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [PausableDownloadURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    private func temporaryDownloadURL(for localURL: URL) -> URL {
        URL(fileURLWithPath: localURL.path + ".download")
    }
}

private final class MockDownloadURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: NSError(domain: "MockDownloadURLProtocol", code: 1))
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private final class PausableDownloadURLProtocol: URLProtocol {
    private static let chunkSize = 300 * 1024
    private static let totalSize = 600 * 1024
    static var firstChunkSent = DispatchSemaphore(value: 0)
    static var finishGate = DispatchSemaphore(value: 0)

    private let stateLock = NSLock()
    private var stopped = false

    static func reset() {
        firstChunkSent = DispatchSemaphore(value: 0)
        finishGate = DispatchSemaphore(value: 0)
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        DispatchQueue.global().async { [weak self] in
            guard let self else {
                return
            }

            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "HTTP/1.1",
                headerFields: [
                    "Content-Length": "\(Self.totalSize)",
                ]
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data(repeating: 0x61, count: Self.chunkSize))
            Self.firstChunkSent.signal()

            _ = Self.finishGate.wait(timeout: .now() + 5)

            guard !isStopped else {
                return
            }

            client?.urlProtocol(self, didLoad: Data(repeating: 0x62, count: Self.totalSize - Self.chunkSize))
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() {
        stateLock.withLock {
            stopped = true
        }
        client?.urlProtocol(self, didFailWithError: URLError(.cancelled))
        Self.finishGate.signal()
    }

    private var isStopped: Bool {
        stateLock.withLock {
            stopped
        }
    }
}

private final class AtomicCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var rawValue = 0

    var value: Int {
        lock.withLock {
            rawValue
        }
    }

    func increment() -> Int {
        lock.withLock {
            rawValue += 1
            return rawValue
        }
    }
}
