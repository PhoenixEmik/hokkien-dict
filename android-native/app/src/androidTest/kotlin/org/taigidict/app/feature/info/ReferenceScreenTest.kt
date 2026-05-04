package org.taigidict.app.feature.info

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
class ReferenceScreenTest {

    @get:Rule
    val composeRule = createAndroidComposeRule<ComponentActivity>()

    @Test
    fun rendersReferenceRows() {
        val context = ApplicationProvider.getApplicationContext<Context>()

        composeRule.setContent {
            MaterialTheme {
                ReferenceScreen(onBack = {})
            }
        }

        composeRule.onNodeWithText(context.getString(R.string.settings_info_reference)).assertIsDisplayed()
        composeRule.onNodeWithText(context.getString(R.string.about_tailo_title)).assertIsDisplayed()
        composeRule.onNodeWithText(context.getString(R.string.about_hanji_title)).assertIsDisplayed()
    }
}
