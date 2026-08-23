import XCTest
@testable import TaigiDictUI

@MainActor
final class AppReviewPromptSchedulerTests: XCTestCase {
    func testFirstLaunchRecordsSeenDateWithoutRequestingReview() {
        let defaults = UserDefaults(suiteName: "AppReviewPromptSchedulerTests.\(UUID().uuidString)")!
        var requestCount = 0
        let now = Date(timeIntervalSince1970: 1_000)

        AppReviewPromptScheduler.maybeRequestReview(now: now, defaults: defaults) {
            requestCount += 1
        }

        XCTAssertEqual(requestCount, 0)
        XCTAssertEqual(defaults.object(forKey: "appReviewPrompt.firstSeenAt") as? Date, now)
    }

    func testReviewIsRequestedAfterInitialDelay() {
        let defaults = UserDefaults(suiteName: "AppReviewPromptSchedulerTests.\(UUID().uuidString)")!
        let firstSeenAt = Date(timeIntervalSince1970: 1_000)
        defaults.set(firstSeenAt, forKey: "appReviewPrompt.firstSeenAt")
        var requestCount = 0

        AppReviewPromptScheduler.maybeRequestReview(
            now: firstSeenAt.addingTimeInterval(7 * 24 * 60 * 60),
            defaults: defaults
        ) {
            requestCount += 1
        }

        XCTAssertEqual(requestCount, 1)
    }

    func testRecentReviewAttemptSuppressesRequest() {
        let defaults = UserDefaults(suiteName: "AppReviewPromptSchedulerTests.\(UUID().uuidString)")!
        let firstSeenAt = Date(timeIntervalSince1970: 1_000)
        let lastAttemptAt = firstSeenAt.addingTimeInterval(10 * 24 * 60 * 60)
        defaults.set(firstSeenAt, forKey: "appReviewPrompt.firstSeenAt")
        defaults.set(lastAttemptAt, forKey: "appReviewPrompt.lastAttemptAt")
        var requestCount = 0

        AppReviewPromptScheduler.maybeRequestReview(
            now: lastAttemptAt.addingTimeInterval(89 * 24 * 60 * 60),
            defaults: defaults
        ) {
            requestCount += 1
        }

        XCTAssertEqual(requestCount, 0)
    }
}
