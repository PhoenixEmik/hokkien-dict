package org.taigidict.app.app

import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.taigidict.app.BuildConfig
import org.taigidict.app.data.repository.RoomDictionaryRepository

@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.DEFAULT_MANIFEST_NAME, sdk = [34])
class RoomDebugBuildVariantTest {
    @Test
    fun appContainer_usesRoomRepositoryBackend() {
        val application = ApplicationProvider.getApplicationContext<TaigiDictApplication>()

        assertEquals("room", BuildConfig.DICTIONARY_REPOSITORY_BACKEND)
        assertTrue(application.appContainer.dictionaryRepository is RoomDictionaryRepository)
    }
}
