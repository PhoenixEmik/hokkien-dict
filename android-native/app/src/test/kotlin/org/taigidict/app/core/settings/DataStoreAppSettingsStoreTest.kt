package org.taigidict.app.core.settings

import android.app.Application
import android.content.Context
import androidx.test.core.app.ApplicationProvider
import java.util.UUID
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@OptIn(ExperimentalCoroutinesApi::class)
@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE, sdk = [34])
class DataStoreAppSettingsStoreTest {
    @Test
    fun themeLanguageAndScale_migrateFromLegacySharedPreferences() = runTest {
        val application = ApplicationProvider.getApplicationContext<Application>()
        val storeName = "app_settings_test_${UUID.randomUUID()}"
        application.getSharedPreferences(storeName, Context.MODE_PRIVATE)
            .edit()
            .putString("theme_preference", AppThemePreference.Dark.name)
            .putString("language_preference", AppLanguagePreference.English.name)
            .putFloat("reading_text_scale", 1.2f)
            .commit()

        val store = DataStoreAppSettingsStore(
            context = application,
            storeName = storeName,
            sharedPreferencesName = storeName,
            scope = backgroundScope,
        )

        assertEquals(AppThemePreference.Dark, store.themePreference.first())
        assertEquals(AppLanguagePreference.English, store.languagePreference.first())
        assertEquals(1.2, store.readingTextScale.first(), 0.0)
    }

    @Test
    fun setReadingTextScale_snapsPersistedValue() = runTest {
        val application = ApplicationProvider.getApplicationContext<Application>()
        val storeName = "app_settings_test_${UUID.randomUUID()}"
        val store = DataStoreAppSettingsStore(
            context = application,
            storeName = storeName,
            sharedPreferencesName = storeName,
            scope = backgroundScope,
        )

        store.setReadingTextScale(1.23)

        assertEquals(1.2, store.readingTextScale.first(), 0.0)
    }
}
