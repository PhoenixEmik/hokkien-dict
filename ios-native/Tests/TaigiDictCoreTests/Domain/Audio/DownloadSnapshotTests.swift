import XCTest
@testable import TaigiDictCore

final class DownloadSnapshotTests: XCTestCase {
    func testProgressReturnsNilWithoutTotalBytes() {
        let snapshot = DownloadSnapshot(state: .downloading, downloadedBytes: 20, totalBytes: nil)
        XCTAssertNil(snapshot.progress)
    }

    func testProgressClampsBetweenZeroAndOne() {
        let half = DownloadSnapshot(state: .downloading, downloadedBytes: 50, totalBytes: 100)
        XCTAssertEqual(half.progress, 0.5)

        let overflow = DownloadSnapshot(state: .downloading, downloadedBytes: 150, totalBytes: 100)
        XCTAssertEqual(overflow.progress, 1.0)
    }
}
