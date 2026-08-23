package org.taigidict.app.feature.info

import androidx.annotation.StringRes
import org.taigidict.app.R

data class ThirdPartyLicenseEntry(
    val id: String,
    val name: String,
    val version: String,
    val license: String,
    val sourceUrl: String,
    val assetPath: String,
    @param:StringRes val descriptionRes: Int,
)

data class ThirdPartyLicenseSection(
    @param:StringRes val titleRes: Int,
    val entries: List<ThirdPartyLicenseEntry>,
)

object ThirdPartyLicenseCatalog {
    val sections = listOf(
        ThirdPartyLicenseSection(
            titleRes = R.string.third_party_core_section,
            entries = listOf(
                ThirdPartyLicenseEntry(
                    id = "android-opencc",
                    name = "android-opencc",
                    version = "1.4.2.1",
                    license = "MIT",
                    sourceUrl = "https://github.com/xyrlsz/android-opencc",
                    assetPath = "third_party_licenses/android_opencc_mit.txt",
                    descriptionRes = R.string.third_party_description_android_opencc,
                ),
                ThirdPartyLicenseEntry(
                    id = "opencc",
                    name = "OpenCC",
                    version = "bundled by android-opencc",
                    license = "Apache 2.0",
                    sourceUrl = "https://github.com/BYVoid/OpenCC",
                    assetPath = "third_party_licenses/apache_2_0.txt",
                    descriptionRes = R.string.third_party_description_opencc,
                ),
                ThirdPartyLicenseEntry(
                    id = "sqlite",
                    name = "SQLite",
                    version = "Android platform",
                    license = "Public Domain",
                    sourceUrl = "https://www.sqlite.org/copyright.html",
                    assetPath = "third_party_licenses/sqlite_public_domain.txt",
                    descriptionRes = R.string.third_party_description_sqlite,
                ),
            ),
        ),
        ThirdPartyLicenseSection(
            titleRes = R.string.third_party_android_section,
            entries = listOf(
                apacheEntry(
                    id = "androidx-core",
                    name = "AndroidX Core",
                    version = "1.16.0",
                    descriptionRes = R.string.third_party_description_androidx_core,
                ),
                apacheEntry(
                    id = "androidx-appcompat",
                    name = "AndroidX AppCompat",
                    version = "1.7.0",
                    descriptionRes = R.string.third_party_description_androidx_appcompat,
                ),
                apacheEntry(
                    id = "androidx-activity-compose",
                    name = "AndroidX Activity Compose",
                    version = "1.10.1",
                    descriptionRes = R.string.third_party_description_androidx_activity_compose,
                ),
                apacheEntry(
                    id = "androidx-lifecycle",
                    name = "AndroidX Lifecycle",
                    version = "2.9.1",
                    descriptionRes = R.string.third_party_description_androidx_lifecycle,
                ),
                apacheEntry(
                    id = "androidx-datastore",
                    name = "AndroidX DataStore Preferences",
                    version = "1.1.1",
                    descriptionRes = R.string.third_party_description_androidx_datastore,
                ),
                apacheEntry(
                    id = "androidx-room",
                    name = "AndroidX Room",
                    version = "2.7.2",
                    descriptionRes = R.string.third_party_description_androidx_room,
                ),
                apacheEntry(
                    id = "compose-bom",
                    name = "Jetpack Compose BOM",
                    version = "2025.06.01",
                    descriptionRes = R.string.third_party_description_compose,
                ),
                apacheEntry(
                    id = "kotlin",
                    name = "Kotlin",
                    version = "2.2.20",
                    sourceUrl = "https://github.com/JetBrains/kotlin",
                    descriptionRes = R.string.third_party_description_kotlin,
                ),
                apacheEntry(
                    id = "kotlinx-serialization",
                    name = "kotlinx.serialization",
                    version = "1.9.0",
                    sourceUrl = "https://github.com/Kotlin/kotlinx.serialization",
                    descriptionRes = R.string.third_party_description_kotlinx_serialization,
                ),
            ),
        ),
    )

    val entries: List<ThirdPartyLicenseEntry> = sections.flatMap { it.entries }

    fun findEntry(id: String): ThirdPartyLicenseEntry? = entries.firstOrNull { it.id == id }

    private fun apacheEntry(
        id: String,
        name: String,
        version: String,
        sourceUrl: String = "https://developer.android.com/jetpack/androidx",
        @StringRes descriptionRes: Int,
    ) = ThirdPartyLicenseEntry(
        id = id,
        name = name,
        version = version,
        license = "Apache 2.0",
        sourceUrl = sourceUrl,
        assetPath = "third_party_licenses/apache_2_0.txt",
        descriptionRes = descriptionRes,
    )
}
