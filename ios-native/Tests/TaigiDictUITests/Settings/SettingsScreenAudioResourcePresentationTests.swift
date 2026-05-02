import XCTest
import TaigiDictCore
@testable import TaigiDictUI

final class SettingsScreenAudioResourcePresentationTests: XCTestCase {
    func testActionMappingPerDownloadState() {
        XCTAssertEqual(
            AudioResourcePresentation.actions(for: DownloadSnapshot(state: .idle)),
            [.start]
        )
        XCTAssertEqual(
            AudioResourcePresentation.actions(for: DownloadSnapshot(state: .downloading)),
            [.pause, .restart]
        )
        XCTAssertEqual(
            AudioResourcePresentation.actions(for: DownloadSnapshot(state: .paused)),
            [.resume, .restart]
        )
        XCTAssertEqual(
            AudioResourcePresentation.actions(for: DownloadSnapshot(state: .completed)),
            [.restart]
        )
        XCTAssertEqual(
            AudioResourcePresentation.actions(for: DownloadSnapshot(state: .failed("network"))),
            [.restart]
        )
    }

    func testDescriptionPerDownloadState() {
        XCTAssertEqual(
            AudioResourcePresentation.description(for: DownloadSnapshot(state: .idle), locale: .traditionalChinese),
            "尚未下載"
        )

        let downloading = DownloadSnapshot(state: .downloading, downloadedBytes: 50, totalBytes: 100)
        XCTAssertTrue(AudioResourcePresentation.description(for: downloading, locale: .traditionalChinese).contains("下載中"))

        let paused = DownloadSnapshot(state: .paused, downloadedBytes: 10, totalBytes: 100)
        XCTAssertTrue(AudioResourcePresentation.description(for: paused, locale: .traditionalChinese).contains("已暫停"))

        let completed = DownloadSnapshot(state: .completed, downloadedBytes: 100, totalBytes: 100)
        XCTAssertTrue(AudioResourcePresentation.description(for: completed, locale: .traditionalChinese).contains("已完成"))

        let failed = DownloadSnapshot(state: .failed("broken zip"), downloadedBytes: 0, totalBytes: nil)
        let failedDescription = AudioResourcePresentation.description(for: failed, locale: .traditionalChinese)
        XCTAssertTrue(failedDescription.contains("失敗"))
        XCTAssertTrue(failedDescription.contains("broken zip"))
    }
}
