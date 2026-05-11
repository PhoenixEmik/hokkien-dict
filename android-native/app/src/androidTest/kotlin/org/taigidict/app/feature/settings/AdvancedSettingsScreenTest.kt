package org.taigidict.app.feature.settings

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
import org.taigidict.app.domain.model.DictionaryBundle

@RunWith(AndroidJUnit4::class)
class AdvancedSettingsScreenTest {

    @get:Rule
    val composeRule = createAndroidComposeRule<ComponentActivity>()

    @Test
    fun rendersSectionsAndMaintenanceActions() {
        val context = ApplicationProvider.getApplicationContext<Context>()

        composeRule.setContent {
            MaterialTheme {
                AdvancedSettingsScreen(
                    uiState = SettingsUiState(
                        bundle = DictionaryBundle(
                            entryCount = 28965,
                            senseCount = 23106,
                            exampleCount = 17700,
                            databasePath = "/data/user/0/org.taigidict.app/files/dictionary.db",
                        ),
                        databasePath = "/data/user/0/org.taigidict.app/files/dictionary.db",
                        builtAt = "2026-04-30 10:12",
                        sourceModifiedAt = "2026-04-30 10:08",
                    ),
                    assetDirectory = "assets/data",
                    onBack = {},
                    onRebuild = {},
                    onClear = {},
                )
            }
        }

        composeRule.onNodeWithText(context.getString(R.string.settings_advanced_title)).assertIsDisplayed()
        composeRule.onNodeWithText(context.getString(R.string.settings_dictionary_title)).assertIsDisplayed()
        composeRule.onNodeWithText(context.getString(R.string.settings_action_rebuild)).assertIsDisplayed()
        composeRule.onNodeWithText(context.getString(R.string.settings_action_clear)).assertIsDisplayed()
    }
}
