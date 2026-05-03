package org.taigidict.app.core.localization

import java.util.Locale
import org.taigidict.app.core.settings.AppLanguagePreference

object AppLocaleResolver {
    fun resolve(languagePreference: AppLanguagePreference): AppLocale {
        return when (languagePreference) {
            AppLanguagePreference.System -> resolveSystemLocale()
            AppLanguagePreference.TraditionalChinese -> AppLocale.TraditionalChinese
            AppLanguagePreference.SimplifiedChinese -> AppLocale.SimplifiedChinese
            AppLanguagePreference.English -> AppLocale.English
        }
    }

    private fun resolveSystemLocale(): AppLocale {
        val locale = Locale.getDefault()
        val language = locale.language.lowercase(Locale.ROOT)
        val country = locale.country.uppercase(Locale.ROOT)

        if (language == "en") {
            return AppLocale.English
        }

        if (language == "zh" && country == "CN") {
            return AppLocale.SimplifiedChinese
        }

        return AppLocale.TraditionalChinese
    }
}