package org.taigidict.app.data.conversion

import android.content.Context
import com.xyrlsz.opencc.android.lib.ChineseConverter
import com.xyrlsz.opencc.android.lib.ConversionType
import org.taigidict.app.core.localization.AppLocale
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock

interface ChineseConversionService {
    suspend fun normalizeSearchInput(text: String, locale: AppLocale): String

    suspend fun translateForDisplay(text: String, locale: AppLocale): String
}

internal class AndroidOpenCcChineseConversionService(
    appContext: Context,
    private val dispatcher: CoroutineDispatcher = Dispatchers.IO,
    private val engine: OpenCcEngine = NativeOpenCcEngine,
) : ChineseConversionService {
    private val context = appContext.applicationContext
    private val lock = Mutex()
    @Volatile
    private var initialized = false

    init {
        runCatching {
            engine.init(context)
            initialized = true
        }
    }

    override suspend fun normalizeSearchInput(text: String, locale: AppLocale): String {
        if (locale != AppLocale.SimplifiedChinese || OpenCcInputGuard.shouldBypass(text)) {
            return text
        }

        return convertSafely(text, OpenCcMode.S2TWP)
    }

    override suspend fun translateForDisplay(text: String, locale: AppLocale): String {
        if (locale != AppLocale.SimplifiedChinese || OpenCcInputGuard.shouldBypass(text)) {
            return text
        }

        return convertSafely(text, OpenCcMode.TW2SP)
    }

    private suspend fun convertSafely(text: String, mode: OpenCcMode): String {
        return withContext(dispatcher) {
            lock.withLock {
                runCatching {
                    if (!initialized) {
                        engine.init(context)
                        initialized = true
                    }
                    engine.convert(text, mode)
                }.getOrDefault(text)
            }
        }
    }
}

internal enum class OpenCcMode {
    S2TWP,
    TW2SP,
}

internal interface OpenCcEngine {
    fun init(context: Context)

    fun convert(text: String, mode: OpenCcMode): String
}

internal object NativeOpenCcEngine : OpenCcEngine {
    override fun init(context: Context) {
        ChineseConverter.init(context)
    }

    override fun convert(text: String, mode: OpenCcMode): String {
        val conversionType = when (mode) {
            OpenCcMode.S2TWP -> ConversionType.S2TWP
            OpenCcMode.TW2SP -> ConversionType.TW2SP
        }
        return ChineseConverter.convert(text, conversionType)
    }
}