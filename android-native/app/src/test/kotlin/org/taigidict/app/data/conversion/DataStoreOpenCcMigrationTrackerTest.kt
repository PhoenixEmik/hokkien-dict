package org.taigidict.app.data.conversion

import android.app.Application
import android.content.Context
import androidx.test.core.app.ApplicationProvider
import java.util.UUID
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@OptIn(ExperimentalCoroutinesApi::class)
@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE, sdk = [34])
class DataStoreOpenCcMigrationTrackerTest {
    @Test
    fun shouldClearDictDataFolder_readsMigratedLegacySharedPreferencesValue() = runTest {
        val application = ApplicationProvider.getApplicationContext<Application>()
        val storeName = "opencc_migrations_test_${UUID.randomUUID()}"
        application.getSharedPreferences(storeName, Context.MODE_PRIVATE)
            .edit()
            .putInt("last_cleared_version_code", 7)
            .commit()

        val tracker = DataStoreOpenCcMigrationTracker(
            context = application,
            storeName = storeName,
            sharedPreferencesName = storeName,
            scope = CoroutineScope(SupervisorJob() + Dispatchers.IO),
        )

        assertFalse(tracker.shouldClearDictDataFolder(7))
        assertTrue(tracker.shouldClearDictDataFolder(8))
    }

    @Test
    fun markDictDataFolderCleared_persistsVersionCode() = runTest {
        val application = ApplicationProvider.getApplicationContext<Application>()
        val storeName = "opencc_migrations_test_${UUID.randomUUID()}"
        val tracker = DataStoreOpenCcMigrationTracker(
            context = application,
            storeName = storeName,
            sharedPreferencesName = storeName,
            scope = CoroutineScope(SupervisorJob() + Dispatchers.IO),
        )

        tracker.markDictDataFolderCleared(5)

        assertFalse(tracker.shouldClearDictDataFolder(5))
        assertTrue(tracker.shouldClearDictDataFolder(6))
    }
}
