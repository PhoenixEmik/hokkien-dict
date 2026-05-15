import XCTest
@testable import TaigiDictUI

final class ThirdPartyLicenseCatalogTests: XCTestCase {
    func testAllThirdPartyLicenseTextsLoadFromBundle() {
        let entries = ThirdPartyLicenseCatalog.directDependencies + ThirdPartyLicenseCatalog.bundledComponents

        for entry in entries {
            XCTAssertFalse(
                entry.licenseText().isEmpty,
                "Expected bundled license text for \(entry.name)"
            )
        }
    }
}
