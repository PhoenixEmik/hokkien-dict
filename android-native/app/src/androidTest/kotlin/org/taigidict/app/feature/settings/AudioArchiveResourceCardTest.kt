package org.taigidict.app.feature.settings

import android.content.Context
import androidx.activity.ComponentActivity
import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.test.assertCountEquals
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onAllNodesWithContentDescription
import androidx.compose.ui.test.onNodeWithContentDescription
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.taigidict.app.R
import org.taigidict.app.data.audio.AudioArchiveDownloadSnapshot
import org.taigidict.app.data.audio.AudioArchiveDownloadState
import org.taigidict.app.data.audio.DictionaryAudioArchiveType

@RunWith(AndroidJUnit4::class)
class AudioArchiveResourceCardTest {

    @get:Rule
    val composeRule = createAndroidComposeRule<ComponentActivity>()

    @Test
    fun downloadingState_hidesRedownloadAction() {
        val context = ApplicationProvider.getApplicationContext<Context>()

        composeRule.setContent {
            MaterialTheme {
                AudioArchiveResourceCard(
                    type = DictionaryAudioArchiveType.Word,
                    snapshot = AudioArchiveDownloadSnapshot(
                        state = AudioArchiveDownloadState.Downloading,
                        downloadedBytes = 28_640_000L,
                        totalBytes = 299_000_000L,
                    ),
                    onAction = {},
                )
            }
        }

        composeRule.onNodeWithContentDescription(
            context.getString(R.string.settings_audio_action_pause),
        ).assertIsDisplayed()
        composeRule.onAllNodesWithContentDescription(
            context.getString(R.string.settings_audio_action_redownload),
        ).assertCountEquals(0)
    }

    @Test
    fun completedState_showsRedownloadAction() {
        val context = ApplicationProvider.getApplicationContext<Context>()

        composeRule.setContent {
            MaterialTheme {
                AudioArchiveResourceCard(
                    type = DictionaryAudioArchiveType.Word,
                    snapshot = AudioArchiveDownloadSnapshot(
                        state = AudioArchiveDownloadState.Completed,
                        downloadedBytes = DictionaryAudioArchiveType.Word.archiveBytes,
                        totalBytes = DictionaryAudioArchiveType.Word.archiveBytes,
                    ),
                    showRedownloadAction = true,
                    onAction = {},
                )
            }
        }

        composeRule.onNodeWithContentDescription(
            context.getString(R.string.settings_audio_action_redownload),
        ).assertIsDisplayed()
    }

    @Test
    fun completedState_hidesRedownloadActionWhenDisabled() {
        val context = ApplicationProvider.getApplicationContext<Context>()

        composeRule.setContent {
            MaterialTheme {
                AudioArchiveResourceCard(
                    type = DictionaryAudioArchiveType.Word,
                    snapshot = AudioArchiveDownloadSnapshot(
                        state = AudioArchiveDownloadState.Completed,
                        downloadedBytes = DictionaryAudioArchiveType.Word.archiveBytes,
                        totalBytes = DictionaryAudioArchiveType.Word.archiveBytes,
                    ),
                    showRedownloadAction = false,
                    onAction = {},
                )
            }
        }

        composeRule.onAllNodesWithContentDescription(
            context.getString(R.string.settings_audio_action_redownload),
        ).assertCountEquals(0)
    }
}
