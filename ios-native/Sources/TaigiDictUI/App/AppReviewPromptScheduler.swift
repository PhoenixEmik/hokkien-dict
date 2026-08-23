import Foundation

enum AppReviewPromptScheduler {
    private static let firstSeenAtKey = "appReviewPrompt.firstSeenAt"
    private static let lastAttemptAtKey = "appReviewPrompt.lastAttemptAt"
    private static let initialReviewPromptDelay: TimeInterval = 7 * 24 * 60 * 60
    private static let reviewPromptCooldown: TimeInterval = 90 * 24 * 60 * 60

    @MainActor
    static func maybeRequestReview(
        now: Date = Date(),
        defaults: UserDefaults = .standard,
        requestReview: () -> Void
    ) {
        guard let firstSeenAt = defaults.object(forKey: firstSeenAtKey) as? Date else {
            defaults.set(now, forKey: firstSeenAtKey)
            return
        }

        guard now.timeIntervalSince(firstSeenAt) >= initialReviewPromptDelay else {
            return
        }

        if let lastAttemptAt = defaults.object(forKey: lastAttemptAtKey) as? Date,
           now.timeIntervalSince(lastAttemptAt) < reviewPromptCooldown {
            return
        }

        defaults.set(now, forKey: lastAttemptAtKey)
        requestReview()
    }
}
