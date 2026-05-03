package org.taigidict.app.data.source

import android.content.res.AssetManager
import java.io.File
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.serialization.SerializationException
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.json.Json
import org.taigidict.app.data.importer.DictionaryManifest
import org.taigidict.app.data.importer.DictionaryJsonlReader

data class DownloadSnapshot(
    val state: State = State.Idle,
    val downloadedBytes: Long = 0,
    val totalBytes: Long? = null,
) {
    enum class State {
        Idle,
        Downloading,
        Paused,
        Completed,
        Failed,
    }

    val progress: Double?
        get() {
            val total = totalBytes ?: return null
            return if (total > 0) {
                (downloadedBytes.toDouble() / total).coerceIn(0.0, 1.0)
            } else {
                null
            }
        }
}

interface DictionarySourceResourceManaging {
    val snapshot: StateFlow<DownloadSnapshot>
    suspend fun refresh(): Result<Unit>
    suspend fun restoreBundledSource(): Result<Unit>
    suspend fun downloadSource(): Result<Unit>
}

class DictionarySourceResourceStore(
    private val assetManager: AssetManager,
    private val bundledManifestAssetPath: String,
    private val bundledEntriesAssetPath: String,
    private val localSourceDirectory: File,
    private val remoteBaseUrl: String = "https://app.taigidict.org/assets/",
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO,
) : DictionarySourceResourceManaging {

    private val _snapshot = MutableStateFlow(DownloadSnapshot())
    override val snapshot: StateFlow<DownloadSnapshot> = _snapshot.asStateFlow()

    private val json = Json { ignoreUnknownKeys = true }
    private val jsonlReader = DictionaryJsonlReader()

    override suspend fun refresh(): Result<Unit> = runCatching {
        val newSnapshot = if (localSourceExists()) {
            val size = localSourceSize()
            DownloadSnapshot(
                state = DownloadSnapshot.State.Completed,
                downloadedBytes = size,
                totalBytes = size,
            )
        } else {
            DownloadSnapshot(state = DownloadSnapshot.State.Idle)
        }
        _snapshot.value = newSnapshot
    }

    override suspend fun restoreBundledSource(): Result<Unit> = runCatching {
        _snapshot.value = DownloadSnapshot(
            state = DownloadSnapshot.State.Downloading,
            downloadedBytes = 0,
            totalBytes = null,
        )

        try {
            localSourceDirectory.mkdirs()

            // Read bundled manifest
            val manifestBytes = assetManager.open(bundledManifestAssetPath).use { it.readBytes() }
            val manifest = json.decodeFromString<DictionaryManifest>(
                manifestBytes.toString(Charsets.UTF_8)
            )

            // Read bundled entries
            val entriesBytes = assetManager.open(bundledEntriesAssetPath).use { it.readBytes() }

            // Write to local directory
            val localManifestFile = File(localSourceDirectory, "dictionary_manifest.json")
            localManifestFile.writeBytes(manifestBytes)

            val localEntriesFile = File(localSourceDirectory, manifest.entriesFileName)
            localEntriesFile.writeBytes(entriesBytes)

            val totalSize = manifestBytes.size.toLong() + entriesBytes.size.toLong()
            _snapshot.value = DownloadSnapshot(
                state = DownloadSnapshot.State.Completed,
                downloadedBytes = totalSize,
                totalBytes = totalSize,
            )
        } catch (error: Exception) {
            _snapshot.value = DownloadSnapshot(
                state = DownloadSnapshot.State.Failed,
                downloadedBytes = _snapshot.value.downloadedBytes,
                totalBytes = _snapshot.value.totalBytes,
            )
            throw error
        }
    }

    override suspend fun downloadSource(): Result<Unit> = runCatching {
        _snapshot.value = DownloadSnapshot(
            state = DownloadSnapshot.State.Downloading,
            downloadedBytes = 0,
            totalBytes = null,
        )

        try {
            localSourceDirectory.mkdirs()

            // Download manifest
            val manifestUrl = "$remoteBaseUrl/dictionary_manifest.json"
            val manifestBytes = downloadFile(manifestUrl)
            val manifest = json.decodeFromString<DictionaryManifest>(
                manifestBytes.toString(Charsets.UTF_8)
            )

            // Download entries
            val entriesUrl = "$remoteBaseUrl/${manifest.entriesFileName}"
            val entriesBytes = downloadFile(entriesUrl)

            // Write to local directory
            val localManifestFile = File(localSourceDirectory, "dictionary_manifest.json")
            localManifestFile.writeBytes(manifestBytes)

            val localEntriesFile = File(localSourceDirectory, manifest.entriesFileName)
            localEntriesFile.writeBytes(entriesBytes)

            val totalSize = manifestBytes.size.toLong() + entriesBytes.size.toLong()
            _snapshot.value = DownloadSnapshot(
                state = DownloadSnapshot.State.Completed,
                downloadedBytes = totalSize,
                totalBytes = totalSize,
            )
        } catch (error: Exception) {
            _snapshot.value = DownloadSnapshot(
                state = DownloadSnapshot.State.Failed,
                downloadedBytes = _snapshot.value.downloadedBytes,
                totalBytes = _snapshot.value.totalBytes,
            )
            throw error
        }
    }

    private fun downloadFile(urlString: String): ByteArray {
        val connection = java.net.URL(urlString).openConnection() as java.net.HttpURLConnection
        return try {
            connection.requestMethod = "GET"
            if (connection.responseCode == 200) {
                connection.inputStream.use { it.readBytes() }
            } else {
                throw Exception("HTTP ${connection.responseCode}: ${connection.responseMessage}")
            }
        } finally {
            connection.disconnect()
        }
    }

    private fun localSourceExists(): Boolean {
        val manifestFile = File(localSourceDirectory, "dictionary_manifest.json")
        if (!manifestFile.exists()) return false

        val manifest = try {
            json.decodeFromString<DictionaryManifest>(
                manifestFile.readBytes().toString(Charsets.UTF_8)
            )
        } catch (e: Exception) {
            return false
        }

        val entriesFile = File(localSourceDirectory, manifest.entriesFileName)
        return entriesFile.exists()
    }

    private fun localSourceSize(): Long {
        val manifestFile = File(localSourceDirectory, "dictionary_manifest.json")
        var size = if (manifestFile.exists()) manifestFile.length() else 0L

        val manifest = try {
            json.decodeFromString<DictionaryManifest>(
                manifestFile.readBytes().toString(Charsets.UTF_8)
            )
        } catch (e: Exception) {
            return size
        }

        val entriesFile = File(localSourceDirectory, manifest.entriesFileName)
        if (entriesFile.exists()) {
            size += entriesFile.length()
        }

        return size
    }
}
