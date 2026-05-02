package org.taigidict.app.data.importer

import android.content.res.AssetManager
import java.security.MessageDigest
import kotlinx.serialization.SerializationException
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.json.Json

sealed class DictionaryPackageLoaderException(message: String, cause: Throwable? = null) :
    Exception(message, cause) {
    class InvalidManifest(detail: String, cause: Throwable? = null) :
        DictionaryPackageLoaderException("Dictionary manifest is invalid: $detail", cause)

    class ChecksumMismatch(expected: String, actual: String) :
        DictionaryPackageLoaderException(
            message = "Dictionary entries checksum mismatch. Expected $expected but was $actual.",
        )

    data object EmptyEntries :
        DictionaryPackageLoaderException("Dictionary entries package is empty.")
}

data class ValidatedDictionaryPackage(
    val manifest: DictionaryManifest,
    val entriesBytes: ByteArray,
    val firstEntry: DictionaryPackageEntry,
)

interface DictionaryPackageLoading {
    fun validateBundledPackage(): ValidatedDictionaryPackage
}

class DictionaryPackageLoader(
    private val assetManager: AssetManager,
    private val manifestAssetPath: String,
    private val entriesAssetDirectory: String,
    private val jsonlReader: DictionaryJsonlReader,
    private val json: Json = Json {
        ignoreUnknownKeys = true
    },
) : DictionaryPackageLoading {
    override fun validateBundledPackage(): ValidatedDictionaryPackage {
        val manifest = loadManifest()
        validateManifest(manifest)

        val entriesAssetPath = "$entriesAssetDirectory/${manifest.entriesFileName}"
        val entriesBytes = assetManager.open(entriesAssetPath).use { inputStream ->
            inputStream.readBytes()
        }

        manifest.checksumSHA256
            ?.takeIf { checksum -> checksum.isNotBlank() }
            ?.let { expectedChecksum ->
                val actualChecksum = sha256Hex(entriesBytes)
                if (!actualChecksum.equals(expectedChecksum, ignoreCase = true)) {
                    throw DictionaryPackageLoaderException.ChecksumMismatch(
                        expected = expectedChecksum,
                        actual = actualChecksum,
                    )
                }
            }

        val firstEntry = jsonlReader.readFirstEntry(entriesBytes)
            ?: throw DictionaryPackageLoaderException.EmptyEntries

        return ValidatedDictionaryPackage(
            manifest = manifest,
            entriesBytes = entriesBytes,
            firstEntry = firstEntry,
        )
    }

    private fun loadManifest(): DictionaryManifest {
        val manifestBytes = assetManager.open(manifestAssetPath).use { inputStream ->
            inputStream.readBytes()
        }

        val manifestString = manifestBytes.toString(Charsets.UTF_8)
        return try {
            json.decodeFromString<DictionaryManifest>(manifestString)
        } catch (error: SerializationException) {
            throw DictionaryPackageLoaderException.InvalidManifest(
                detail = error.message ?: error.toString(),
                cause = error,
            )
        }
    }

    private fun validateManifest(manifest: DictionaryManifest) {
        if (manifest.schemaVersion != SUPPORTED_SCHEMA_VERSION) {
            throw DictionaryPackageLoaderException.InvalidManifest(
                detail = "Unsupported schema version ${manifest.schemaVersion}.",
            )
        }
        if (manifest.entryCount <= 0) {
            throw DictionaryPackageLoaderException.InvalidManifest(
                detail = "Entry count must be positive.",
            )
        }
        if (manifest.senseCount < 0 || manifest.exampleCount < 0) {
            throw DictionaryPackageLoaderException.InvalidManifest(
                detail = "Sense and example counts must not be negative.",
            )
        }
        if (manifest.entriesFileName.isBlank()) {
            throw DictionaryPackageLoaderException.InvalidManifest(
                detail = "entriesFileName must not be blank.",
            )
        }
    }

    private fun sha256Hex(bytes: ByteArray): String {
        val digest = MessageDigest.getInstance("SHA-256").digest(bytes)
        return digest.joinToString(separator = "") { byte ->
            "%02x".format(byte.toInt() and 0xff)
        }
    }

    private companion object {
        const val SUPPORTED_SCHEMA_VERSION = 1
    }
}