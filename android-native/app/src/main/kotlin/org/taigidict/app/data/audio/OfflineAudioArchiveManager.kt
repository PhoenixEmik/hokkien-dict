package org.taigidict.app.data.audio

import java.io.File
import java.io.IOException
import java.io.InputStream
import java.net.HttpURLConnection
import java.net.URL
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

internal class OfflineAudioArchiveManager(
    filesDirectory: File,
    private val storage: DictionaryAudioArchiveStorage = DictionaryAudioArchiveStorage(
        rootDirectory = File(filesDirectory, DictionaryAudioArchiveStorage.ROOT_DIRECTORY_NAME),
    ),
    private val zipIndexer: StoredZipAudioIndexer = StoredZipAudioIndexer(),
    private val connectionFactory: AudioArchiveConnectionFactory = DefaultAudioArchiveConnectionFactory(),
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO,
    private val managerScope: CoroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.IO),
) {
    private val snapshots = DictionaryAudioArchiveType.entries.associateWith { type ->
        MutableStateFlow(
            AudioArchiveDownloadSnapshot(
                state = AudioArchiveDownloadState.Idle,
                downloadedBytes = 0,
                totalBytes = type.archiveBytes,
            ),
        )
    }
    private val activeJobs = mutableMapOf<DictionaryAudioArchiveType, Job?>()

    fun snapshotFlow(type: DictionaryAudioArchiveType): StateFlow<AudioArchiveDownloadSnapshot> {
        return snapshots.getValue(type).asStateFlow()
    }

    fun refreshAll(): List<Job> {
        return DictionaryAudioArchiveType.entries.map(::refresh)
    }

    fun refresh(type: DictionaryAudioArchiveType): Job {
        return managerScope.launch {
            publishLocalSnapshot(type)
        }
    }

    @Synchronized
    fun startDownload(type: DictionaryAudioArchiveType): Job {
        if (activeJobs[type]?.isActive == true) {
            return activeJobs.getValue(type)!!
        }

        val job = managerScope.launch {
            downloadArchive(type = type, allowResume = true)
        }
        activeJobs[type] = job
        return job
    }

    fun resumeDownload(type: DictionaryAudioArchiveType): Job {
        return startDownload(type)
    }

    @Synchronized
    fun pauseDownload(type: DictionaryAudioArchiveType): Job? {
        val currentJob = activeJobs[type] ?: return null
        return managerScope.launch {
            currentJob.cancelAndJoin()
            synchronized(this@OfflineAudioArchiveManager) {
                if (activeJobs[type] === currentJob) {
                    activeJobs[type] = null
                }
            }
            publishLocalSnapshot(type)
        }
    }

    @Synchronized
    fun restartDownload(type: DictionaryAudioArchiveType): Job {
        val currentJob = activeJobs[type]
        val restartJob = managerScope.launch {
            currentJob?.cancelAndJoin()
            clearArchiveState(type)
            updateSnapshot(type) {
                AudioArchiveDownloadSnapshot(
                    state = AudioArchiveDownloadState.Idle,
                    downloadedBytes = 0,
                    totalBytes = type.archiveBytes,
                )
            }
            downloadArchive(type = type, allowResume = false)
        }
        activeJobs[type] = restartJob
        return restartJob
    }

    private suspend fun downloadArchive(
        type: DictionaryAudioArchiveType,
        allowResume: Boolean,
    ) {
        try {
            withContext(ioDispatcher) {
                storage.ensureDirectories()
                val archiveFile = storage.archiveFile(type)
                val tempFile = storage.downloadTempFile(type)
                val resumeBytes = if (allowResume && tempFile.exists()) tempFile.length() else 0L
                val connection = connectionFactory.open(type.sourceUrl, resumeBytes)

                connection.use {
                    val responseCode = connection.responseCode
                    val appendToTemp = resumeBytes > 0 && responseCode == HttpURLConnection.HTTP_PARTIAL
                    if (resumeBytes > 0 && !appendToTemp && tempFile.exists()) {
                        tempFile.delete()
                    }

                    val baseDownloadedBytes = if (appendToTemp) resumeBytes else 0L
                    val responseBytes = connection.contentLength.coerceAtLeast(0)
                    val resolvedTotalBytes = when {
                        appendToTemp && responseBytes > 0 -> baseDownloadedBytes + responseBytes
                        responseBytes > 0 -> responseBytes
                        archiveFile.exists() -> archiveFile.length()
                        else -> type.archiveBytes
                    }

                    updateSnapshot(type) {
                        AudioArchiveDownloadSnapshot(
                            state = AudioArchiveDownloadState.Downloading,
                            downloadedBytes = baseDownloadedBytes,
                            totalBytes = resolvedTotalBytes,
                        )
                    }

                    tempFile.parentFile?.mkdirs()
                    tempFile.outputStream().buffered().use { output ->
                        if (appendToTemp) {
                            output.write(tempFile.readBytes())
                        }
                    }

                    if (appendToTemp) {
                        appendStreamToFile(
                            inputStream = connection.inputStream,
                            targetFile = tempFile,
                            append = true,
                            type = type,
                            baseDownloadedBytes = baseDownloadedBytes,
                            totalBytes = resolvedTotalBytes,
                        )
                    } else {
                        appendStreamToFile(
                            inputStream = connection.inputStream,
                            targetFile = tempFile,
                            append = false,
                            type = type,
                            baseDownloadedBytes = 0,
                            totalBytes = resolvedTotalBytes,
                        )
                    }
                }

                val index = zipIndexer.buildIndex(tempFile)
                if (index[type.validationClipId] == null) {
                    throw ZipIndexNotFoundException()
                }

                if (archiveFile.exists()) {
                    archiveFile.delete()
                }
                if (!tempFile.renameTo(archiveFile)) {
                    throw IOException("Failed to move downloaded archive into place.")
                }
                storage.clearCachedClips(type)
                updateSnapshot(type) {
                    AudioArchiveDownloadSnapshot(
                        state = AudioArchiveDownloadState.Completed,
                        downloadedBytes = archiveFile.length(),
                        totalBytes = archiveFile.length(),
                    )
                }
            }
        } catch (error: CancellationException) {
            publishLocalSnapshot(type)
        } catch (error: IOException) {
            updateSnapshot(type) {
                AudioArchiveDownloadSnapshot(
                    state = AudioArchiveDownloadState.Failed,
                    downloadedBytes = currentDownloadedBytes(type),
                    totalBytes = type.archiveBytes,
                    errorMessage = error.message,
                )
            }
        } finally {
            synchronized(this) {
                val currentJob = activeJobs[type]
                if (currentJob != null && !currentJob.isActive) {
                    activeJobs[type] = null
                }
            }
        }
    }

    private suspend fun appendStreamToFile(
        inputStream: InputStream,
        targetFile: File,
        append: Boolean,
        type: DictionaryAudioArchiveType,
        baseDownloadedBytes: Long,
        totalBytes: Long,
    ) {
        if (!append && targetFile.exists()) {
            targetFile.delete()
        }

        targetFile.outputStream().buffered().use { output ->
            if (append && targetFile.exists()) {
                output.write(targetFile.readBytes())
            }
            inputStream.buffered().use { input ->
                val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
                var downloadedBytes = baseDownloadedBytes
                while (true) {
                    val bytesRead = input.read(buffer)
                    if (bytesRead <= 0) {
                        break
                    }
                    output.write(buffer, 0, bytesRead)
                    downloadedBytes += bytesRead
                    updateSnapshot(type) {
                        AudioArchiveDownloadSnapshot(
                            state = AudioArchiveDownloadState.Downloading,
                            downloadedBytes = downloadedBytes,
                            totalBytes = totalBytes,
                        )
                    }
                }
            }
        }
    }

    private suspend fun clearArchiveState(type: DictionaryAudioArchiveType) {
        withContext(ioDispatcher) {
            storage.archiveFile(type).delete()
            storage.downloadTempFile(type).delete()
            storage.clearCachedClips(type)
        }
    }

    private suspend fun publishLocalSnapshot(type: DictionaryAudioArchiveType) {
        val snapshot = withContext(ioDispatcher) {
            storage.ensureDirectories()
            val archiveFile = storage.findArchiveFile(type)
            if (archiveFile != null) {
                return@withContext try {
                    val index = zipIndexer.buildIndex(archiveFile)
                    if (index[type.validationClipId] != null) {
                        AudioArchiveDownloadSnapshot(
                            state = AudioArchiveDownloadState.Completed,
                            downloadedBytes = archiveFile.length(),
                            totalBytes = archiveFile.length(),
                        )
                    } else {
                        AudioArchiveDownloadSnapshot(
                            state = AudioArchiveDownloadState.Failed,
                            downloadedBytes = archiveFile.length(),
                            totalBytes = archiveFile.length(),
                            errorMessage = "Archive validation failed.",
                        )
                    }
                } catch (error: IOException) {
                    AudioArchiveDownloadSnapshot(
                        state = AudioArchiveDownloadState.Failed,
                        downloadedBytes = archiveFile.length(),
                        totalBytes = archiveFile.length(),
                        errorMessage = error.message,
                    )
                }
            }

            val tempFile = storage.downloadTempFile(type)
            if (tempFile.exists()) {
                AudioArchiveDownloadSnapshot(
                    state = AudioArchiveDownloadState.Paused,
                    downloadedBytes = tempFile.length(),
                    totalBytes = type.archiveBytes,
                )
            } else {
                AudioArchiveDownloadSnapshot(
                    state = AudioArchiveDownloadState.Idle,
                    downloadedBytes = 0,
                    totalBytes = type.archiveBytes,
                )
            }
        }

        updateSnapshot(type) { snapshot }
    }

    private fun currentDownloadedBytes(type: DictionaryAudioArchiveType): Long {
        return snapshots.getValue(type).value.downloadedBytes
    }

    private fun updateSnapshot(
        type: DictionaryAudioArchiveType,
        transform: (AudioArchiveDownloadSnapshot) -> AudioArchiveDownloadSnapshot,
    ) {
        snapshots.getValue(type).update(transform)
    }
}

internal data class AudioArchiveDownloadSnapshot(
    val state: AudioArchiveDownloadState,
    val downloadedBytes: Long,
    val totalBytes: Long,
    val errorMessage: String? = null,
) {
    val progress: Float?
        get() = if (totalBytes > 0) downloadedBytes.toFloat() / totalBytes.toFloat() else null
}

internal enum class AudioArchiveDownloadState {
    Idle,
    Downloading,
    Paused,
    Completed,
    Failed,
}

internal interface AudioArchiveConnectionFactory {
    fun open(url: String, resumeFromByte: Long): AudioArchiveConnection
}

internal interface AudioArchiveConnection : AutoCloseable {
    val responseCode: Int
    val contentLength: Long
    val inputStream: InputStream
}

internal class DefaultAudioArchiveConnectionFactory : AudioArchiveConnectionFactory {
    override fun open(url: String, resumeFromByte: Long): AudioArchiveConnection {
        val connection = (URL(url).openConnection() as HttpURLConnection).apply {
            requestMethod = "GET"
            connectTimeout = 15_000
            readTimeout = 30_000
            setRequestProperty("Accept-Encoding", "identity")
            if (resumeFromByte > 0) {
                setRequestProperty("Range", "bytes=$resumeFromByte-")
            }
            connect()
        }
        return HttpUrlAudioArchiveConnection(connection)
    }
}

internal class HttpUrlAudioArchiveConnection(
    private val connection: HttpURLConnection,
) : AudioArchiveConnection {
    override val responseCode: Int
        get() = connection.responseCode

    override val contentLength: Long
        get() = connection.contentLengthLong

    override val inputStream: InputStream
        get() = connection.inputStream

    override fun close() {
        connection.disconnect()
    }
}