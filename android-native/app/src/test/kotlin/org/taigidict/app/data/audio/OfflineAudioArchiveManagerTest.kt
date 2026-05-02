package org.taigidict.app.data.audio

import java.io.ByteArrayInputStream
import java.io.File
import java.nio.file.Files
import java.util.zip.CRC32
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.joinAll
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
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
}

private class FakeAudioArchiveConnectionFactory(
    private val payload: ByteArray,
) : AudioArchiveConnectionFactory {
    override fun open(url: String, resumeFromByte: Long): AudioArchiveConnection {
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