package org.taigidict.app.data.importer

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.taigidict.app.core.constants.AppConstants

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class DictionaryPackageLoaderTest {
    @Test
    fun validateBundledPackage_readsGeneratedAssets() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val loader = DictionaryPackageLoader(
            assetManager = context.assets,
            manifestAssetPath = AppConstants.BUNDLED_DICTIONARY_MANIFEST_ASSET_PATH,
            entriesAssetDirectory = AppConstants.BUNDLED_DICTIONARY_ASSET_DIRECTORY,
            jsonlReader = DictionaryJsonlReader(),
        )

        val validatedPackage = loader.validateBundledPackage()

        assertEquals(28_965, validatedPackage.manifest.entryCount)
        assertEquals(23_106, validatedPackage.manifest.senseCount)
        assertEquals(17_700, validatedPackage.manifest.exampleCount)
        assertEquals(1L, validatedPackage.firstEntry.id)
        assertNotNull(validatedPackage.entriesBytes)
    }
}