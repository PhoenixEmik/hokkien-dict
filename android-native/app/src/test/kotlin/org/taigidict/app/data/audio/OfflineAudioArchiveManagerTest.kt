package org.taigidict.app.data.audio

import java.io.ByteArrayInputStream
import java.io.File
import java.io.IOException
import java.nio.file.Files
import java.util.zip.CRC32
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.joinAll
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class OfflineAudioArchiveManagerTest {
    @Test
    fun refreshAll_withExistingArchive_marksSnapshotCompleted() = runTest {
        val rootDirectory = Files.createTempDirectory("audio-archive-refresh").toFile()
        val archiveFile = File(
            File(File(rootDirectory, DictionaryAudioArchiveStorage.ROOT_DIRECTORY_NAME), "archives"),
            DictionaryAudioArchiveType.Word.archiveFileName,
        )
        writeStoredZipFile(
            archiveFile = archiveFile,
            entries = mapOf(
                "word/1(1).mp3" to "validation".toByteArray(),
            ),
        )
        val manager = OfflineAudioArchiveManager(
            filesDirectory = rootDirectory,
            managerScope = backgroundScope,
            ioDispatcher = StandardTestDispatcher(testScheduler),
        )

        manager.refreshAll().joinAll()

        val snapshot = manager.snapshotFlow(DictionaryAudioArchiveType.Word).value
        assertEquals(AudioArchiveDownloadState.Completed, snapshot.state)
        assertEquals(archiveFile.length(), snapshot.downloadedBytes)
    }

    @Test
    fun refreshAll_withExistingArchiveWithoutCurrentDictionaryMetadata_requestsUpdate() = runTest {
        val rootDirectory = Files.createTempDirectory("audio-archive-refresh-stale").toFile()
        val archiveFile = File(
            File(File(rootDirectory, DictionaryAudioArchiveStorage.ROOT_DIRECTORY_NAME), "archives"),
            DictionaryAudioArchiveType.Word.archiveFileName,
        )
        writeStoredZipFile(
            archiveFile = archiveFile,
            entries = mapOf(
                "word/1(1).mp3" to "validation".toByteArray(),
            ),
        )
        val manager = OfflineAudioArchiveManager(
            filesDirectory = rootDirectory,
            managerScope = backgroundScope,
            ioDispatcher = StandardTestDispatcher(testScheduler),
            expectedDictionaryEntriesChecksum = "current-checksum",
        )

        manager.refreshAll().joinAll()

        val snapshot = manager.snapshotFlow(DictionaryAudioArchiveType.Word).value
        assertEquals(AudioArchiveDownloadState.Completed, snapshot.state)
        assertTrue(snapshot.needsDictionaryUpdate)
    }

    @Test
    fun startDownload_downloadsAndStoresArchive() = runTest {
        val rootDirectory = Files.createTempDirectory("audio-archive-download").toFile()
        val archiveBytes = buildStoredZipBytes(
            mapOf(
                "word/1(1).mp3" to "validation".toByteArray(),
                "word/example.mp3" to "example".toByteArray(),
            ),
        )
        val manager = OfflineAudioArchiveManager(
            filesDirectory = rootDirectory,
            connectionFactory = FakeAudioArchiveConnectionFactory(archiveBytes),
            managerScope = backgroundScope,
            ioDispatcher = StandardTestDispatcher(testScheduler),
        )

        manager.startDownload(DictionaryAudioArchiveType.Word).join()

        val snapshot = manager.snapshotFlow(DictionaryAudioArchiveType.Word).value
        val storedArchive = File(
            File(File(rootDirectory, DictionaryAudioArchiveStorage.ROOT_DIRECTORY_NAME), "archives"),
            DictionaryAudioArchiveType.Word.archiveFileName,
        )
        assertEquals(AudioArchiveDownloadState.Completed, snapshot.state)
        assertTrue(storedArchive.exists())
        assertEquals(storedArchive.length(), snapshot.downloadedBytes)
    }

    @Test
    fun startDownload_recordsCurrentDictionaryMetadata() = runTest {
        val rootDirectory = Files.createTempDirectory("audio-archive-download-current").toFile()
        val archiveBytes = buildStoredZipBytes(
            mapOf(
                "word/1(1).mp3" to "validation".toByteArray(),
            ),
        )
        val manager = OfflineAudioArchiveManager(
            filesDirectory = rootDirectory,
            connectionFactory = FakeAudioArchiveConnectionFactory(archiveBytes),
            managerScope = backgroundScope,
            ioDispatcher = StandardTestDispatcher(testScheduler),
            expectedDictionaryEntriesChecksum = "current-checksum",
        )

        manager.startDownload(DictionaryAudioArchiveType.Word).join()

        val snapshot = manager.snapshotFlow(DictionaryAudioArchiveType.Word).value
        val metadataFile = File(
            File(File(rootDirectory, DictionaryAudioArchiveStorage.ROOT_DIRECTORY_NAME), "archives"),
            "sutiau-mp3.metadata.properties",
        )
        assertEquals(AudioArchiveDownloadState.Completed, snapshot.state)
        assertEquals(false, snapshot.needsDictionaryUpdate)
        assertTrue(metadataFile.readText().contains("current-checksum"))
    }

    @Test
    fun resumeDownload_withPartialTempFile_requestsRangeAndCompletesArchive() = runTest {
        val rootDirectory = Files.createTempDirectory("audio-archive-resume").toFile()
        val archiveBytes = buildStoredZipBytes(
            mapOf(
                "word/1(1).mp3" to "validation".toByteArray(),
                "word/example.mp3" to "example".toByteArray(),
            ),
        )
        val partialBytes = archiveBytes.copyOfRange(0, archiveBytes.size / 2)
        val tempDownloadFile = File(
            File(File(rootDirectory, DictionaryAudioArchiveStorage.ROOT_DIRECTORY_NAME), "archives"),
            "${DictionaryAudioArchiveType.Word.archiveFileName}.download",
        )
        tempDownloadFile.parentFile?.mkdirs()
        tempDownloadFile.writeBytes(partialBytes)

        val connectionFactory = FakeAudioArchiveConnectionFactory(archiveBytes)
        val manager = OfflineAudioArchiveManager(
            filesDirectory = rootDirectory,
            connectionFactory = connectionFactory,
            managerScope = backgroundScope,
            ioDispatcher = StandardTestDispatcher(testScheduler),
        )

        manager.resumeDownload(DictionaryAudioArchiveType.Word).join()

        val snapshot = manager.snapshotFlow(DictionaryAudioArchiveType.Word).value
        val storedArchive = File(
            File(File(rootDirectory, DictionaryAudioArchiveStorage.ROOT_DIRECTORY_NAME), "archives"),
            DictionaryAudioArchiveType.Word.archiveFileName,
        )
        assertEquals(AudioArchiveDownloadState.Completed, snapshot.state)
        assertTrue(storedArchive.exists())
        assertEquals(archiveBytes.size.toLong(), storedArchive.length())
        assertEquals(archiveBytes.toList(), storedArchive.readBytes().toList())
        assertTrue(connectionFactory.resumeFromByteRequests.contains(partialBytes.size.toLong()))
    }

    @Test
    fun pauseDownload_duringActiveDownload_marksSnapshotPaused() = runTest {
        val rootDirectory = Files.createTempDirectory("audio-archive-pause").toFile()
        val manager = OfflineAudioArchiveManager(
            filesDirectory = rootDirectory,
            connectionFactory = SlowAudioArchiveConnectionFactory(totalBytes = 5_000_000L),
            managerScope = CoroutineScope(SupervisorJob() + Dispatchers.IO),
            ioDispatcher = Dispatchers.IO,
        )

        manager.startDownload(DictionaryAudioArchiveType.Word)
        val pauseJob = manager.pauseDownload(DictionaryAudioArchiveType.Word)
        assertNotNull(pauseJob)
        pauseJob?.join()

        val snapshot = manager.snapshotFlow(DictionaryAudioArchiveType.Word).value
        assertEquals(AudioArchiveDownloadState.Paused, snapshot.state)
    }
}

private class FakeAudioArchiveConnectionFactory(
    private val payload: ByteArray,
) : AudioArchiveConnectionFactory {
    val resumeFromByteRequests = mutableListOf<Long>()

    override fun open(url: String, resumeFromByte: Long): AudioArchiveConnection {
        resumeFromByteRequests += resumeFromByte
        val bytes = if (resumeFromByte > 0) payload.copyOfRange(resumeFromByte.toInt(), payload.size) else payload
        val responseCode = if (resumeFromByte > 0) 206 else 200
        return FakeAudioArchiveConnection(
            payload = bytes,
            responseCode = responseCode,
        )
    }
}

private class FakeAudioArchiveConnection(
    payload: ByteArray,
    override val responseCode: Int,
) : AudioArchiveConnection {
    override val contentLength: Long = payload.size.toLong()
    override val inputStream = ByteArrayInputStream(payload)

    override fun close() = Unit
}

private class SlowAudioArchiveConnectionFactory(
    private val totalBytes: Long,
) : AudioArchiveConnectionFactory {
    override fun open(url: String, resumeFromByte: Long): AudioArchiveConnection {
        return SlowAudioArchiveConnection(
            totalBytes = (totalBytes - resumeFromByte).coerceAtLeast(0),
            responseCode = if (resumeFromByte > 0) 206 else 200,
        )
    }
}

private class SlowAudioArchiveConnection(
    totalBytes: Long,
    override val responseCode: Int,
) : AudioArchiveConnection {
    @Volatile
    private var closed = false

    private val stream = object : java.io.InputStream() {
        var emitted = 0L

        override fun read(): Int {
            if (closed) throw IOException("closed")
            if (emitted >= totalBytes) return -1
            Thread.sleep(1)
            emitted += 1
            return 0x41
        }
    }

    override val contentLength: Long = totalBytes
    override val inputStream = stream

    override fun close() {
        closed = true
    }
}

private fun buildStoredZipBytes(entries: Map<String, ByteArray>): ByteArray {
    val tempFile = Files.createTempFile("stored-audio", ".zip").toFile()
    writeStoredZipFile(tempFile, entries)
    return tempFile.readBytes()
}

private fun writeStoredZipFile(
    archiveFile: File,
    entries: Map<String, ByteArray>,
) {
    archiveFile.parentFile?.mkdirs()
    ZipOutputStream(archiveFile.outputStream().buffered()).use { output ->
        for ((name, bytes) in entries) {
            val crc = CRC32().apply { update(bytes) }
            val entry = ZipEntry(name).apply {
                method = ZipEntry.STORED
                size = bytes.size.toLong()
                compressedSize = bytes.size.toLong()
                this.crc = crc.value
            }
            output.putNextEntry(entry)
            output.write(bytes)
            output.closeEntry()
        }
    }
}
