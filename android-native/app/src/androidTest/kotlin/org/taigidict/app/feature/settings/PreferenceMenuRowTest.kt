package org.taigidict.app.feature.settings

import android.content.Context
import androidx.activity.ComponentActivity
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import org.taigidict.app.R
import org.taigidict.app.core.settings.AppLanguagePreference

@RunWith(AndroidJUnit4::class)
class PreferenceMenuRowTest {

    @get:Rule
    val composeRule = createAndroidComposeRule<ComponentActivity>()

    @Test
    fun expandsMenuAndSelectsLanguageOption() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        var selected by mutableStateOf(AppLanguagePreference.TraditionalChinese)

        composeRule.setContent {
            MaterialTheme {
                PreferenceMenuRow(
                    title = context.getString(R.string.settings_language_title),
                    value = context.languageLabel(selected),
                    options = AppLanguagePreference.entries,
                    selectedOption = selected,
                    optionLabel = { context.languageLabel(it) },
                    onSelect = { selected = it },
                )
            }
        }

        composeRule.onNodeWithText(context.getString(R.string.settings_language_title)).performClick()
        composeRule.onNodeWithText(context.getString(R.string.settings_language_japanese)).assertIsDisplayed()

        composeRule.onNodeWithText(context.getString(R.string.settings_language_japanese)).performClick()
        composeRule.onNodeWithText(context.getString(R.string.settings_language_japanese)).assertIsDisplayed()
    }

    private fun Context.languageLabel(preference: AppLanguagePreference): String {
        return when (preference) {
            AppLanguagePreference.System -> getString(R.string.settings_language_system)
            AppLanguagePreference.TraditionalChinese -> getString(R.string.settings_language_traditional_chinese)
            AppLanguagePreference.SimplifiedChinese -> getString(R.string.settings_language_simplified_chinese)
            AppLanguagePreference.English -> getString(R.string.settings_language_english)
            AppLanguagePreference.Japanese -> getString(R.string.settings_language_japanese)
        }
    }
}
