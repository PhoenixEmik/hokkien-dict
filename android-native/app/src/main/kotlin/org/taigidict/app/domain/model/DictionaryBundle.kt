package org.taigidict.app.domain.model

data class DictionaryBundle(
    val entryCount: Int,
    val senseCount: Int,
    val exampleCount: Int,
    val databasePath: String? = null,
) {
    val isDatabaseBacked: Boolean
        get() = !databasePath.isNullOrBlank()
}