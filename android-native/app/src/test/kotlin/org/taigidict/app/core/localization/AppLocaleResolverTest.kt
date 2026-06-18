package org.taigidict.app.core.localization

import java.util.Locale
import org.junit.Assert.assertEquals
import org.junit.Test
import org.taigidict.app.core.settings.AppLanguagePreference

class AppLocaleResolverTest {
    @Test
    fun japanesePreference_resolvesJapaneseLocale() {
        assertEquals(
            AppLocale.Japanese,
            AppLocaleResolver.resolve(AppLanguagePreference.Japanese),
        )
    }

    @Test
    fun japaneseSystemLocale_resolvesJapaneseLocale() {
        val previousLocale = Locale.getDefault()
        try {
            Locale.setDefault(Locale.JAPANESE)

            assertEquals(
                AppLocale.Japanese,
                AppLocaleResolver.resolve(AppLanguagePreference.System),
            )
        } finally {
            Locale.setDefault(previousLocale)
        }
    }
}
