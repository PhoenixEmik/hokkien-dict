package org.taigidict.app.feature.review

import android.app.Activity
import android.content.Context
import com.google.android.play.core.review.ReviewManagerFactory

class AppReviewPromptCoordinator(
    private val activity: Activity,
    private val nowMillis: () -> Long = { System.currentTimeMillis() },
) {
    private val preferences = activity.getSharedPreferences(PreferencesName, Context.MODE_PRIVATE)

    fun maybeRequestReview() {
        val now = nowMillis()
        val firstSeenAt = preferences.getLong(FirstSeenAtKey, MissingTimestamp)
        if (firstSeenAt == MissingTimestamp) {
            preferences.edit()
                .putLong(FirstSeenAtKey, now)
                .apply()
            return
        }

        if (now - firstSeenAt < InitialReviewPromptDelayMillis) {
            return
        }

        val lastAttemptAt = preferences.getLong(LastAttemptAtKey, MissingTimestamp)
        if (lastAttemptAt != MissingTimestamp && now - lastAttemptAt < ReviewPromptCooldownMillis) {
            return
        }

        preferences.edit()
            .putLong(LastAttemptAtKey, now)
            .apply()

        val manager = ReviewManagerFactory.create(activity)
        manager.requestReviewFlow().addOnCompleteListener { request ->
            if (!request.isSuccessful || activity.isFinishing || activity.isDestroyed) {
                return@addOnCompleteListener
            }

            manager.launchReviewFlow(activity, request.result)
        }
    }

    private companion object {
        private const val PreferencesName = "app_review_prompt"
        private const val FirstSeenAtKey = "first_seen_at_ms"
        private const val LastAttemptAtKey = "last_attempt_at_ms"
        private const val MissingTimestamp = 0L
        private const val DayMillis = 24L * 60L * 60L * 1000L
        private const val InitialReviewPromptDelayMillis = 7L * DayMillis
        private const val ReviewPromptCooldownMillis = 90L * DayMillis
    }
}
