import XCTest
import Foundation
import TaigiDictCore
@testable import TaigiDictUI

final class TaigiDictAppRootViewTests: XCTestCase {
    func testInitialPresentationShowsInitializationInsteadOfBlankContent() {
        XCTAssertEqual(
            AppRootContentPresentation.resolve(isInitializationReady: false),
            .initialization
        )
    }

    func testReadyPresentationShowsMainTabs() {
        XCTAssertEqual(
            AppRootContentPresentation.resolve(isInitializationReady: true),
            .mainTabs
        )
    }

    func testOfflineAudioBootstrapPreloadsAllArchiveTypes() async {
        let store = SpyOfflineAudioStore()

        await AppRootOfflineAudioBootstrap.preload(using: store)

        let requestedTypes = await store.requestedTypes
        XCTAssertEqual(requestedTypes, AudioArchiveType.allCases)
    }
}

private actor SpyOfflineAudioStore: OfflineAudioManaging {
    private(set) var requestedTypes: [AudioArchiveType] = []

    func snapshot(for type: AudioArchiveType) async -> DownloadSnapshot {
        requestedTypes.append(type)
        return DownloadSnapshot()
    }

    func startDownload(_ type: AudioArchiveType) async {}

    func pauseDownload(_ type: AudioArchiveType) async {}

    func resumeDownload(_ type: AudioArchiveType) async {}

    func restartDownload(_ type: AudioArchiveType) async {}

    func playClip(_ clipID: String, from type: AudioArchiveType) async throws {}

    func currentlyPlayingClipID() async -> String? {
        nil
    }
}
