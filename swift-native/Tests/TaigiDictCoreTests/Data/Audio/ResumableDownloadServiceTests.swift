import Foundation
import XCTest
@testable import TaigiDictCore

final class ResumableDownloadServiceTests: XCTestCase {
    override class func setUp() {
        super.setUp()
        MockDownloadURLProtocol.handler = nil
    }

    override class func tearDown() {
        MockDownloadURLProtocol.handler = nil
        super.tearDown()
    }

    func testResumeFallsBackToFullDownloadWhenServerIgnoresRange() async throws {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
            .appendingPathComponent("ResumableDownloadServiceTests-\(UUID().uuidString)", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)

        let localURL = directory.appendingPathComponent("audio.zip")
        let initialData = Data("OLD".utf8)
        try initialData.write(to: localURL)

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

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockDownloadURLProtocol.self]
        return URLSession(configuration: configuration)
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
