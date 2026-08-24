package org.taigidict.app.data.source

import android.content.res.AssetManager
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.io.InputStream
import java.net.HttpURLConnection
import java.net.URL
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.withContext
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.json.Json
import org.taigidict.app.data.importer.DictionaryManifest
import org.taigidict.app.data.importer.DictionaryJsonlReader
import org.taigidict.app.data.importer.LocalDictionaryPackageLoader

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
    suspend fun restoreBundledSourceIfNewer(): Result<Boolean>
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

    companion object {
        private const val CONNECTION_TIMEOUT_MS = 15_000
        private const val READ_TIMEOUT_MS = 15_000
    }

    private val _snapshot = MutableStateFlow(DownloadSnapshot())
    override val snapshot: StateFlow<DownloadSnapshot> = _snapshot.asStateFlow()

    private val json = Json { ignoreUnknownKeys = true }
    private val jsonlReader = DictionaryJsonlReader()
    private val stagingSourceDirectory = File(
        localSourceDirectory.parentFile,
        "${localSourceDirectory.name}.staging",
    )
    private val backupSourceDirectory = File(
        localSourceDirectory.parentFile,
        "${localSourceDirectory.name}.backup",
    )
    private val activeNetworkLock = Any()

    @Volatile
    private var activeConnection: HttpURLConnection? = null

    @Volatile
    private var activeInputStream: InputStream? = null

    override suspend fun refresh(): Result<Unit> = withContext(ioDispatcher) {
        runCatching {
            val newSnapshot = if (hasValidLocalSource()) {
                val size = localSourceSize(localSourceDirectory)
                DownloadSnapshot(
                    state = DownloadSnapshot.State.Completed,
                    downloadedBytes = size,
                    totalBytes = size,
                )
            } else if (localSourceSizeIncludingTemp(stagingSourceDirectory) > 0L) {
                DownloadSnapshot(
                    state = DownloadSnapshot.State.Paused,
                    downloadedBytes = localSourceSizeIncludingTemp(stagingSourceDirectory),
                    totalBytes = null,
                )
            } else {
                DownloadSnapshot(state = DownloadSnapshot.State.Idle)
            }
            _snapshot.value = newSnapshot
        }
    }

    override suspend fun restoreBundledSource(): Result<Unit> = withContext(ioDispatcher) {
        runCatching {
            _snapshot.value = DownloadSnapshot(
                state = DownloadSnapshot.State.Downloading,
                downloadedBytes = 0,
                totalBytes = null,
            )

            try {
                resetDirectory(stagingSourceDirectory)

                val manifestBytes = assetManager.open(bundledManifestAssetPath).use { it.readBytes() }
                val manifest = json.decodeFromString<DictionaryManifest>(
                    manifestBytes.toString(Charsets.UTF_8)
                )
                val entriesBytes = assetManager.open(bundledEntriesAssetPath).use { it.readBytes() }

                val localManifestFile = File(stagingSourceDirectory, "dictionary_manifest.json")
                localManifestFile.writeBytes(manifestBytes)

                val localEntriesFile = File(stagingSourceDirectory, manifest.entriesFileName)
                localEntriesFile.writeBytes(entriesBytes)

                validateLocalSource(stagingSourceDirectory)
                promoteStagingSource()
                publishCompletedSnapshotFromValidatedLocalSource()
            } catch (error: Exception) {
                clearDirectory(stagingSourceDirectory)
                _snapshot.value = DownloadSnapshot(
                    state = DownloadSnapshot.State.Failed,
                    downloadedBytes = _snapshot.value.downloadedBytes,
                    totalBytes = _snapshot.value.totalBytes,
                )
                throw error
            }
        }
    }

    override suspend fun restoreBundledSourceIfNewer(): Result<Boolean> = withContext(ioDispatcher) {
        runCatching {
            val bundledManifest = readBundledManifest()
            val localManifest = readManifestOrNull(localSourceDirectory)
            val localEntriesExists = localManifest?.let { manifest ->
                File(localSourceDirectory, manifest.entriesFileName).exists()
            } ?: false

            val shouldRestore = !localEntriesExists || bundledManifest.isNewerThan(localManifest)
            if (!shouldRestore) {
                return@runCatching false
            }

            restoreBundledSource().getOrThrow()
            true
        }
    }

    override suspend fun downloadSource(): Result<Unit> = withContext(ioDispatcher) {
        runCatching {
            _snapshot.value = DownloadSnapshot(
                state = DownloadSnapshot.State.Downloading,
                downloadedBytes = localSourceSizeIncludingTemp(stagingSourceDirectory),
                totalBytes = null,
            )

            try {
                val manifestUrl = "$remoteBaseUrl/dictionary_manifest.json"
                val manifestBytes = downloadFile(manifestUrl)
                val manifest = json.decodeFromString<DictionaryManifest>(
                    manifestBytes.toString(Charsets.UTF_8)
                )
                prepareStagingDirectory(manifest, manifestBytes)

                val tempEntriesFile = File(stagingSourceDirectory, "${manifest.entriesFileName}.download")
                val localEntriesFile = File(stagingSourceDirectory, manifest.entriesFileName)
                val resumeBytes = if (tempEntriesFile.exists()) tempEntriesFile.length() else 0L

                val entriesUrl = "$remoteBaseUrl/${manifest.entriesFileName}"
                downloadEntriesFile(
                    urlString = entriesUrl,
                    targetTempFile = tempEntriesFile,
                    resumeBytes = resumeBytes,
                    baseDownloadedBytes = manifestBytes.size.toLong(),
                )

                if (localEntriesFile.exists() && !localEntriesFile.delete()) {
                    throw IOException("Failed to clear stale dictionary entries staging file.")
                }
                if (!tempEntriesFile.renameTo(localEntriesFile)) {
                    throw IOException("Failed to move downloaded dictionary entries into place.")
                }

                validateLocalSource(stagingSourceDirectory)
                promoteStagingSource()
                publishCompletedSnapshotFromValidatedLocalSource()
            } catch (error: CancellationException) {
                val pausedBytes = localSourceSizeIncludingTemp(stagingSourceDirectory)
                _snapshot.value = DownloadSnapshot(
                    state = DownloadSnapshot.State.Paused,
                    downloadedBytes = pausedBytes,
                    totalBytes = _snapshot.value.totalBytes,
                )
                throw error
            } catch (error: Exception) {
                clearDirectory(stagingSourceDirectory)
                _snapshot.value = DownloadSnapshot(
                    state = DownloadSnapshot.State.Failed,
                    downloadedBytes = _snapshot.value.downloadedBytes,
                    totalBytes = _snapshot.value.totalBytes,
                )
                throw error
            }
        }
    }

    override suspend fun pauseDownload(): Result<Unit> = withContext(ioDispatcher) {
        runCatching {
            cancelActiveNetworkRequests()
            val pausedBytes = localSourceSizeIncludingTemp(stagingSourceDirectory)
            _snapshot.value = DownloadSnapshot(
                state = DownloadSnapshot.State.Paused,
                downloadedBytes = pausedBytes,
                totalBytes = _snapshot.value.totalBytes,
            )
        }
    }

    override suspend fun resumeDownload(): Result<Unit> {
        return downloadSource()
    }

    private fun prepareStagingDirectory(
        manifest: DictionaryManifest,
        manifestBytes: ByteArray,
    ) {
        val currentManifest = readManifestOrNull(stagingSourceDirectory)
        val shouldResetStaging =
            currentManifest?.entriesFileName != manifest.entriesFileName ||
                currentManifest.checksumSHA256 != manifest.checksumSHA256
        if (shouldResetStaging) {
            resetDirectory(stagingSourceDirectory)
        } else {
            stagingSourceDirectory.mkdirs()
        }

        stagingSourceDirectory.listFiles()?.forEach { file ->
            if (file.name != "dictionary_manifest.json" && file.name != "${manifest.entriesFileName}.download") {
                if (file.isDirectory) {
                    clearDirectory(file)
                } else if (!file.delete()) {
                    throw IOException("Failed to clear stale staging file ${file.path}.")
                }
            }
        }

        File(stagingSourceDirectory, "dictionary_manifest.json").writeBytes(manifestBytes)
    }

    private suspend fun downloadFile(urlString: String): ByteArray {
        val connection = openManagedConnection(urlString)
        return try {
            connection.requestMethod = "GET"
            if (connection.responseCode == 200) {
                connection.inputStream.use { input ->
                    registerActiveInputStream(input)
                    try {
                        val output = ByteArrayOutputStream()
                        val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
                        val coroutineContext = currentCoroutineContext()
                        while (true) {
                            coroutineContext.ensureActive()
                            val read = input.read(buffer)
                            if (read <= 0) {
                                break
                            }
                            output.write(buffer, 0, read)
                        }
                        output.toByteArray()
                    } finally {
                        clearActiveInputStream(input)
                    }
                }
            } else {
                throw Exception("HTTP ${connection.responseCode}: ${connection.responseMessage}")
            }
        } finally {
            clearActiveConnection(connection)
        }
    }

    private suspend fun downloadEntriesFile(
        urlString: String,
        targetTempFile: File,
        resumeBytes: Long,
        baseDownloadedBytes: Long,
    ): Long {
        val connection = openManagedConnection(urlString).apply {
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
                registerActiveInputStream(input)
                try {
                    FileOutputStream(targetTempFile, canAppend).buffered().use { output ->
                        val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
                        var downloaded = startingBytes
                        val coroutineContext = currentCoroutineContext()
                        while (true) {
                            coroutineContext.ensureActive()
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
                } finally {
                    clearActiveInputStream(input)
                }
            }

            return targetTempFile.length()
        } finally {
            clearActiveConnection(connection)
        }
    }

    private fun openManagedConnection(urlString: String): HttpURLConnection {
        return (URL(urlString).openConnection() as HttpURLConnection).apply {
            connectTimeout = CONNECTION_TIMEOUT_MS
            readTimeout = READ_TIMEOUT_MS
            synchronized(activeNetworkLock) {
                activeConnection = this
            }
        }
    }

    private fun registerActiveInputStream(inputStream: InputStream) {
        synchronized(activeNetworkLock) {
            activeInputStream = inputStream
        }
    }

    private fun clearActiveInputStream(inputStream: InputStream) {
        synchronized(activeNetworkLock) {
            if (activeInputStream === inputStream) {
                activeInputStream = null
            }
        }
    }

    private fun clearActiveConnection(connection: HttpURLConnection) {
        synchronized(activeNetworkLock) {
            if (activeConnection === connection) {
                activeConnection = null
            }
            connection.disconnect()
        }
    }

    private fun cancelActiveNetworkRequests() {
        synchronized(activeNetworkLock) {
            runCatching { activeInputStream?.close() }
            activeInputStream = null
            activeConnection?.disconnect()
            activeConnection = null
        }
    }

    private fun hasValidLocalSource(): Boolean {
        return runCatching {
            validateLocalSource(localSourceDirectory)
        }.isSuccess
    }

    private fun validateLocalSource(sourceDirectory: File) {
        LocalDictionaryPackageLoader(
            sourceDirectory = sourceDirectory,
            jsonlReader = jsonlReader,
            json = json,
        ).validateBundledPackage()
    }

    private fun localSourceSize(sourceDirectory: File): Long {
        val manifestFile = File(sourceDirectory, "dictionary_manifest.json")
        var size = if (manifestFile.exists()) manifestFile.length() else 0L

        val manifest = try {
            json.decodeFromString<DictionaryManifest>(
                manifestFile.readBytes().toString(Charsets.UTF_8)
            )
        } catch (e: Exception) {
            return size
        }

        val entriesFile = File(sourceDirectory, manifest.entriesFileName)
        if (entriesFile.exists()) {
            size += entriesFile.length()
        }

        return size
    }

    private fun localSourceSizeIncludingTemp(sourceDirectory: File): Long {
        val committed = localSourceSize(sourceDirectory)
        val tempSize = sourceDirectory.listFiles()
            ?.filter { it.name.endsWith(".download") }
            ?.sumOf { it.length() }
            ?: 0L
        return committed + tempSize
    }

    private fun publishCompletedSnapshotFromValidatedLocalSource() {
        validateLocalSource(localSourceDirectory)

        val totalSize = localSourceSize(localSourceDirectory)
        _snapshot.value = DownloadSnapshot(
            state = DownloadSnapshot.State.Completed,
            downloadedBytes = totalSize,
            totalBytes = totalSize,
        )
    }

    private fun promoteStagingSource() {
        clearDirectory(backupSourceDirectory)

        val movedExistingSource = if (localSourceDirectory.exists()) {
            if (!localSourceDirectory.renameTo(backupSourceDirectory)) {
                throw IOException("Failed to move existing dictionary source out of the way.")
            }
            true
        } else {
            false
        }

        try {
            if (!stagingSourceDirectory.renameTo(localSourceDirectory)) {
                throw IOException("Failed to move staged dictionary source into place.")
            }
            clearDirectory(backupSourceDirectory)
        } catch (error: Exception) {
            if (movedExistingSource && backupSourceDirectory.exists() && !backupSourceDirectory.renameTo(localSourceDirectory)) {
                error.addSuppressed(
                    IOException("Failed to restore previous dictionary source."),
                )
            }
            throw error
        }
    }

    private fun readManifestOrNull(sourceDirectory: File): DictionaryManifest? {
        val manifestFile = File(sourceDirectory, "dictionary_manifest.json")
        if (!manifestFile.exists()) {
            return null
        }

        return runCatching {
            json.decodeFromString<DictionaryManifest>(
                manifestFile.readBytes().toString(Charsets.UTF_8)
            )
        }.getOrNull()
    }

    private fun readBundledManifest(): DictionaryManifest {
        val manifestBytes = assetManager.open(bundledManifestAssetPath).use { it.readBytes() }
        return json.decodeFromString(manifestBytes.toString(Charsets.UTF_8))
    }

    private fun DictionaryManifest.isNewerThan(other: DictionaryManifest?): Boolean {
        if (other == null) {
            return true
        }

        val checksum = checksumSHA256?.takeIf(String::isNotBlank)
        val otherChecksum = other.checksumSHA256?.takeIf(String::isNotBlank)
        if (checksum != null && checksum.equals(otherChecksum, ignoreCase = true)) {
            return false
        }

        val sourceModifiedAt = sourceModifiedAt?.takeIf(String::isNotBlank)
        val otherSourceModifiedAt = other.sourceModifiedAt?.takeIf(String::isNotBlank)
        if (sourceModifiedAt != null && otherSourceModifiedAt != null) {
            return sourceModifiedAt > otherSourceModifiedAt
        }

        return this != other
    }

    private fun resetDirectory(directory: File) {
        clearDirectory(directory)
        if (!directory.exists() && !directory.mkdirs()) {
            throw IOException("Failed to create ${directory.path}.")
        }
    }

    private fun clearDirectory(directory: File) {
        if (!directory.exists()) {
            return
        }

        directory.listFiles()?.forEach { file ->
            val deleted = if (file.isDirectory) {
                file.deleteRecursively()
            } else {
                file.delete()
            }
            if (!deleted) {
                throw IOException("Failed to delete ${file.path}.")
            }
        }

        if (directory !== localSourceDirectory && directory.exists() && !directory.delete()) {
            throw IOException("Failed to delete ${directory.path}.")
        }
    }
}
