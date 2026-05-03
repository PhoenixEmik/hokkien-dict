package org.taigidict.app.data.source

import android.content.res.AssetManager
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URL
import kotlinx.coroutines.CancellationException
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
    suspend fun pauseDownload(): Result<Unit>
    suspend fun resumeDownload(): Result<Unit>
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
            downloadedBytes = _snapshot.value.downloadedBytes,
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

            val tempEntriesFile = File(localSourceDirectory, "${manifest.entriesFileName}.download")
            val localEntriesFile = File(localSourceDirectory, manifest.entriesFileName)
            val resumeBytes = if (tempEntriesFile.exists()) tempEntriesFile.length() else 0L

            // Download entries with resume support
            val entriesUrl = "$remoteBaseUrl/${manifest.entriesFileName}"
            val entriesSize = downloadEntriesFile(
                urlString = entriesUrl,
                targetTempFile = tempEntriesFile,
                resumeBytes = resumeBytes,
                baseDownloadedBytes = manifestBytes.size.toLong(),
            )

            // Write to local directory
            val localManifestFile = File(localSourceDirectory, "dictionary_manifest.json")
            localManifestFile.writeBytes(manifestBytes)

            if (localEntriesFile.exists()) {
                localEntriesFile.delete()
            }
            if (!tempEntriesFile.renameTo(localEntriesFile)) {
                throw IOException("Failed to move downloaded dictionary entries into place.")
            }

            val totalSize = manifestBytes.size.toLong() + entriesSize
            _snapshot.value = DownloadSnapshot(
                state = DownloadSnapshot.State.Completed,
                downloadedBytes = totalSize,
                totalBytes = totalSize,
            )
        } catch (error: CancellationException) {
            val pausedBytes = localSourceSizeIncludingTemp()
            _snapshot.value = DownloadSnapshot(
                state = DownloadSnapshot.State.Paused,
                downloadedBytes = pausedBytes,
                totalBytes = _snapshot.value.totalBytes,
            )
            throw error
        } catch (error: Exception) {
            _snapshot.value = DownloadSnapshot(
                state = DownloadSnapshot.State.Failed,
                downloadedBytes = _snapshot.value.downloadedBytes,
                totalBytes = _snapshot.value.totalBytes,
            )
            throw error
        }
    }

    override suspend fun pauseDownload(): Result<Unit> = runCatching {
        val pausedBytes = localSourceSizeIncludingTemp()
        _snapshot.value = DownloadSnapshot(
            state = DownloadSnapshot.State.Paused,
            downloadedBytes = pausedBytes,
            totalBytes = _snapshot.value.totalBytes,
        )
    }

    override suspend fun resumeDownload(): Result<Unit> {
        return downloadSource()
    }

    private fun downloadFile(urlString: String): ByteArray {
        val connection = URL(urlString).openConnection() as HttpURLConnection
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

    private fun downloadEntriesFile(
        urlString: String,
        targetTempFile: File,
        resumeBytes: Long,
        baseDownloadedBytes: Long,
    ): Long {
        val connection = (URL(urlString).openConnection() as HttpURLConnection).apply {
            requestMethod = "GET"
            if (resumeBytes > 0) {
                setRequestProperty("Range", "bytes=$resumeBytes-")
            }
            setRequestProperty("Accept-Encoding", "identity")
        }

        try {
            val responseCode = connection.responseCode
            val canAppend = resumeBytes > 0 && responseCode == HttpURLConnection.HTTP_PARTIAL
            if (responseCode != HttpURLConnection.HTTP_OK && responseCode != HttpURLConnection.HTTP_PARTIAL) {
                throw Exception("HTTP $responseCode: ${connection.responseMessage}")
            }

            if (!canAppend && targetTempFile.exists()) {
                targetTempFile.delete()
            }

            targetTempFile.parentFile?.mkdirs()

            val startingBytes = if (canAppend) resumeBytes else 0L
            val contentLength = connection.contentLengthLong.takeIf { it > 0 }
            val totalBytes = contentLength?.let {
                baseDownloadedBytes + if (canAppend) startingBytes + it else it
            }

            connection.inputStream.use { input ->
                FileOutputStream(targetTempFile, canAppend).buffered().use { output ->
                    val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
                    var downloaded = startingBytes
                    while (true) {
                        val read = input.read(buffer)
                        if (read <= 0) {
                            break
                        }
                        output.write(buffer, 0, read)
                        downloaded += read.toLong()
                        _snapshot.value = DownloadSnapshot(
                            state = DownloadSnapshot.State.Downloading,
                            downloadedBytes = baseDownloadedBytes + downloaded,
                            totalBytes = totalBytes,
                        )
                    }
                }
            }

            return targetTempFile.length()
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

    private fun localSourceSizeIncludingTemp(): Long {
        val committed = localSourceSize()
        val tempSize = localSourceDirectory.listFiles()
            ?.filter { it.name.endsWith(".download") }
            ?.sumOf { it.length() }
            ?: 0L
        return committed + tempSize
    }
}
