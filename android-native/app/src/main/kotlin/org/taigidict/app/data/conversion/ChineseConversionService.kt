package org.taigidict.app.data.conversion

import org.taigidict.app.core.localization.AppLocale

interface ChineseConversionService {
    suspend fun normalizeSearchInput(text: String, locale: AppLocale): String

    suspend fun translateForDisplay(text: String, locale: AppLocale): String
}

class GuardedNoOpChineseConversionService : ChineseConversionService {
    override suspend fun normalizeSearchInput(text: String, locale: AppLocale): String {
        if (locale != AppLocale.SimplifiedChinese) {
            return text
        }
        if (OpenCcInputGuard.shouldBypass(text)) {
            return text
        }
        return text
    }

    override suspend fun translateForDisplay(text: String, locale: AppLocale): String {
        if (locale != AppLocale.SimplifiedChinese) {
            return text
        }
        if (OpenCcInputGuard.shouldBypass(text)) {
            return text
        }
        return text
    }
}