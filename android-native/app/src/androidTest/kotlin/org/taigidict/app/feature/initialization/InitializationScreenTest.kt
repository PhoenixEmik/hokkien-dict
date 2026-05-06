package org.taigidict.app.feature.initialization

import android.content.Context
import androidx.activity.ComponentActivity
import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.taigidict.app.R

@RunWith(AndroidJUnit4::class)
class InitializationScreenTest {

    @get:Rule
    val composeRule = createAndroidComposeRule<ComponentActivity>()

    @Test
    fun rebuildingState_rendersPhaseProgressAndEntryCounts() {
        val context = ApplicationProvider.getApplicationContext<Context>()

        composeRule.setContent {
            MaterialTheme {
                InitializationScreen(
                    uiState = InitializationUiState(
                        phase = InitializationPhase.RebuildingDatabase,
                        progress = 0.56f,
                        processedEntries = 280,
                        totalEntries = 500,
                        isReady = false,
                    ),
                    onRetry = {},
                )
            }
        }

        composeRule.onNodeWithText(context.getString(R.string.initialization_title)).assertIsDisplayed()
        composeRule.onNodeWithText(
            context.getString(R.string.initialization_phase_rebuilding_database),
        ).assertIsDisplayed()
        composeRule.onNodeWithText("56%").assertIsDisplayed()
        composeRule.onNodeWithText("280 / 500").assertIsDisplayed()
    }

    @Test
    fun errorState_rendersMessageAndRetryButton() {
        val context = ApplicationProvider.getApplicationContext<Context>()

        composeRule.setContent {
            MaterialTheme {
                InitializationScreen(
                    uiState = InitializationUiState(
                        phase = InitializationPhase.Error,
                        errorMessage = "Dictionary package is invalid.",
                        isReady = false,
                    ),
                    onRetry = {},
                )
            }
        }

        composeRule.onNodeWithText(
            context.getString(R.string.initialization_phase_error),
        ).assertIsDisplayed()
        composeRule.onNodeWithText("Dictionary package is invalid.").assertIsDisplayed()
        composeRule.onNodeWithText(context.getString(R.string.retry)).assertIsDisplayed()
    }
}
