import XCTest
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
}
