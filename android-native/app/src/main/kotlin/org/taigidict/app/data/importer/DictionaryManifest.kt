package org.taigidict.app.data.importer

import kotlinx.serialization.Serializable

@Serializable
data class DictionaryManifest(
    val schemaVersion: Int,
    val builtAt: String,
    val source: String? = null,
    val sourceModifiedAt: String? = null,
    val entryCount: Int,
    val senseCount: Int,
    val exampleCount: Int,
    val entriesFileName: String,
    val checksumSHA256: String? = null,
)