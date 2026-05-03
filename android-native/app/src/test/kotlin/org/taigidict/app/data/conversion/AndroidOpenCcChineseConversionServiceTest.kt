package org.taigidict.app.data.conversion

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import org.taigidict.app.core.localization.AppLocale

@OptIn(ExperimentalCoroutinesApi::class)
@RunWith(RobolectricTestRunner::class)
@Config(manifest = Config.NONE, sdk = [34])
class AndroidOpenCcChineseConversionServiceTest {
    private val dispatcher = StandardTestDispatcher()

    @Test
    fun normalizeSearchInput_usesS2TwpInSimplifiedChinese() = runTest(dispatcher) {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val engine = FakeOpenCcEngine(converted = "辭典")
        val service = AndroidOpenCcChineseConversionService(
            appContext = context,
            dispatcher = dispatcher,
            engine = engine,
        )

        val output = service.normalizeSearchInput("词典", AppLocale.SimplifiedChinese)

        assertEquals("辭典", output)
        assertEquals(listOf(OpenCcMode.S2TWP), engine.modes)
        assertEquals(listOf("词典"), engine.inputs)
    }

    @Test
    fun translateForDisplay_usesTw2SpInSimplifiedChinese() = runTest(dispatcher) {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val engine = FakeOpenCcEngine(converted = "词典")
        val service = AndroidOpenCcChineseConversionService(
            appContext = context,
            dispatcher = dispatcher,
            engine = engine,
        )

        val output = service.translateForDisplay("辭典", AppLocale.SimplifiedChinese)

        assertEquals("词典", output)
        assertEquals(listOf(OpenCcMode.TW2SP), engine.modes)
        assertEquals(listOf("辭典"), engine.inputs)
    }

    @Test
    fun conversionFailure_fallsBackToOriginalText() = runTest(dispatcher) {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val engine = FakeOpenCcEngine(shouldThrow = true)
        val service = AndroidOpenCcChineseConversionService(
            appContext = context,
            dispatcher = dispatcher,
            engine = engine,
        )

        val output = service.normalizeSearchInput("词典", AppLocale.SimplifiedChinese)

        assertEquals("词典", output)
    }

    @Test
    fun romanizationBypassesConversion() = runTest(dispatcher) {
        val context = ApplicationProvider.getApplicationContext<Context>()
        val engine = FakeOpenCcEngine(converted = "should-not-use")
        val service = AndroidOpenCcChineseConversionService(
            appContext = context,
            dispatcher = dispatcher,
            engine = engine,
        )

        val output = service.normalizeSearchInput("su-tian", AppLocale.SimplifiedChinese)

        assertEquals("su-tian", output)
        assertTrue(engine.modes.isEmpty())
    }
}

private class FakeOpenCcEngine(
    private val converted: String = "",
    private val shouldThrow: Boolean = false,
) : OpenCcEngine {
    val modes = mutableListOf<OpenCcMode>()
    val inputs = mutableListOf<String>()

    override fun init(context: Context) {
    }

    override fun convert(text: String, mode: OpenCcMode): String {
        if (shouldThrow) {
            throw RuntimeException("test conversion failure")
        }
        inputs += text
        modes += mode
        return converted
    }
}