package org.taigidict.app.data.importer

import java.io.File
import java.security.MessageDigest
import kotlinx.serialization.SerializationException
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.json.Json

class LocalDictionaryPackageLoader(
    private val sourceDirectory: File,
    private val jsonlReader: DictionaryJsonlReader,
    private val json: Json = Json {
        ignoreUnknownKeys = true
    },
) : DictionaryPackageLoading {
    override fun validateBundledPackage(): ValidatedDictionaryPackage {
        val manifestFile = File(sourceDirectory, "dictionary_manifest.json")
        if (!manifestFile.exists()) {
            throw DictionaryPackageLoaderException.InvalidManifest(
                detail = "dictionary_manifest.json is missing in ${sourceDirectory.path}",
            )
        }

        val manifest = try {
            json.decodeFromString<DictionaryManifest>(manifestFile.readText(Charsets.UTF_8))
        } catch (error: SerializationException) {
            throw DictionaryPackageLoaderException.InvalidManifest(
                detail = error.message ?: error.toString(),
                cause = error,
            )
        }

        validateManifest(manifest)

        val entriesFile = File(sourceDirectory, manifest.entriesFileName)
        if (!entriesFile.exists()) {
            throw DictionaryPackageLoaderException.InvalidManifest(
                detail = "${manifest.entriesFileName} is missing in ${sourceDirectory.path}",
            )
        }

        val entriesBytes = entriesFile.readBytes()

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