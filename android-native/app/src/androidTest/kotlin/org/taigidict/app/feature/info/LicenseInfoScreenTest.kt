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
class LicenseInfoScreenTest {

    @get:Rule
    val composeRule = createAndroidComposeRule<ComponentActivity>()

    @Test
    fun rendersLicenseRowsAndThirdPartyEntry() {
        val context = ApplicationProvider.getApplicationContext<Context>()

        composeRule.setContent {
            MaterialTheme {
                LicenseSummaryScreen(
                    onBack = {},
                    onOpenThirdPartyLicenses = {},
                )
            }
        }

        composeRule.onNodeWithText(context.getString(R.string.settings_info_open_source_license)).assertIsDisplayed()
        composeRule.onNodeWithText(context.getString(R.string.license_app_code_title)).assertIsDisplayed()
        composeRule.onNodeWithText(context.getString(R.string.license_data_title)).assertIsDisplayed()
        composeRule.onNodeWithText(context.getString(R.string.license_audio_title)).assertIsDisplayed()
        composeRule.onNodeWithText(context.getString(R.string.license_third_party_title)).assertIsDisplayed()
    }
}
