package org.taigidict.app.data.audio

import android.media.MediaPlayer
import java.io.File
import java.io.IOException
import java.io.RandomAccessFile
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.taigidict.app.domain.model.DictionaryEntry
import org.taigidict.app.domain.model.DictionaryExample

internal class OfflineDictionaryAudioPlayer(
    filesDirectory: File,
    private val storage: DictionaryAudioArchiveStorage = DictionaryAudioArchiveStorage(
        rootDirectory = File(filesDirectory, DictionaryAudioArchiveStorage.ROOT_DIRECTORY_NAME),
    ),
    private val zipIndexer: StoredZipAudioIndexer = StoredZipAudioIndexer(),
    private val playbackController: AudioPlaybackController = MediaPlayerAudioPlaybackController(),
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO,
) : DictionaryAudioPlayer {
    private val cachedIndexes = mutableMapOf<DictionaryAudioArchiveType, Map<String, StoredZipEntryLocation>>()

    override suspend fun playEntryAudio(entry: DictionaryEntry): DictionaryAudioPlaybackResult {
        return playClip(
            clipId = entry.audioId,
            archiveType = DictionaryAudioArchiveType.Word,
        )
    }

    override suspend fun playExampleAudio(example: DictionaryExample): DictionaryAudioPlaybackResult {
        return playClip(
            clipId = example.audioId,
            archiveType = DictionaryAudioArchiveType.Sentence,
        )
    }

    private suspend fun playClip(
        clipId: String,
        archiveType: DictionaryAudioArchiveType,
    ): DictionaryAudioPlaybackResult = withContext(ioDispatcher) {
        if (clipId.isBlank()) {
            return@withContext DictionaryAudioPlaybackResult.Failed(
                DictionaryAudioPlaybackResult.FailureReason.MissingClipId,
            )
        }

        try {
            storage.ensureDirectories()
            val archiveFile = storage.findArchiveFile(archiveType)
                ?: return@withContext DictionaryAudioPlaybackResult.Failed(
                    DictionaryAudioPlaybackResult.FailureReason.ArchiveNotDownloaded,
                )
            val index = cachedIndexes[archiveType] ?: buildAndCacheIndex(archiveType, archiveFile)
            val entry = index[clipId] ?: return@withContext DictionaryAudioPlaybackResult.Failed(
                DictionaryAudioPlaybackResult.FailureReason.AudioClipNotFound,
            )
            val clipFile = storage.clipCacheFile(archiveType, clipId)
            zipIndexer.materializeEntry(
                archiveFile = archiveFile,
                outputFile = clipFile,
                entry = entry,
            )
            playbackController.play(
                clipFile = clipFile,
                clipKey = "${archiveType.storageKey}:$clipId",
            )
            DictionaryAudioPlaybackResult.Played
        } catch (
            error: IOException,
        ) {
            unavailableResult()
        } catch (
            error: IllegalArgumentException,
        ) {
            unavailableResult()
        } catch (
            error: SecurityException,
        ) {
            unavailableResult()
        } catch (
            error: StoredZipEntryFormatException,
        ) {
            unavailableResult()
        } catch (
            error: ZipIndexNotFoundException,
        ) {
            unavailableResult()
        } catch (
            error: ZipLocalHeaderFormatException,
        ) {
            unavailableResult()
        }
    }

    private fun buildAndCacheIndex(
        archiveType: DictionaryAudioArchiveType,
        archiveFile: File,
    ): Map<String, StoredZipEntryLocation> {
        val index = zipIndexer.buildIndex(archiveFile)
        if (index[archiveType.validationClipId] == null) {
            throw ZipIndexNotFoundException()
        }
        cachedIndexes[archiveType] = index
        return index
    }

    private fun unavailableResult(): DictionaryAudioPlaybackResult {
        return DictionaryAudioPlaybackResult.Failed(
            DictionaryAudioPlaybackResult.FailureReason.AudioNotAvailable,
        )
    }
}

internal enum class DictionaryAudioArchiveType(
    val storageKey: String,
    val archiveFileName: String,
    val legacyArchiveFileName: String,
    val validationClipId: String,
    val archiveBytes: Long,
    val sourceUrl: String,
) {
    Word(
        storageKey = "word",
        archiveFileName = "sutiau-mp3.zip",
        legacyArchiveFileName = "sutiau_mp3.zip",
        validationClipId = "1(1)",
        archiveBytes = 298531008,
        sourceUrl = "https://app.taigidict.org/assets/sutiau-mp3.zip",
    ),
    Sentence(
        storageKey = "sentence",
        archiveFileName = "leku-mp3.zip",
        legacyArchiveFileName = "leku_mp3.zip",
        validationClipId = "1-1-1",
        archiveBytes = 514423301,
        sourceUrl = "https://app.taigidict.org/assets/leku-mp3.zip",
    ),
}

internal class DictionaryAudioArchiveStorage(
    private val rootDirectory: File,
) {
    fun ensureDirectories() {
        rootDirectory.mkdirs()
        archivesDirectory().mkdirs()
        clipsDirectory().mkdirs()
    }

    fun archiveFile(type: DictionaryAudioArchiveType): File {
        return File(archivesDirectory(), type.archiveFileName)
    }

    fun downloadTempFile(type: DictionaryAudioArchiveType): File {
        return File(archivesDirectory(), "${type.archiveFileName}.download")
    }

    fun findArchiveFile(type: DictionaryAudioArchiveType): File? {
        return archiveCandidates(type).firstOrNull(File::exists)
    }

    fun clipCacheFile(type: DictionaryAudioArchiveType, clipId: String): File {
        val safeClipId = clipId.replace(Regex("[^0-9A-Za-z()_-]"), "_")
        return File(File(clipsDirectory(), type.storageKey), "$safeClipId.mp3")
    }

    fun clearCachedClips(type: DictionaryAudioArchiveType) {
        File(clipsDirectory(), type.storageKey).deleteRecursively()
    }

    private fun archiveCandidates(type: DictionaryAudioArchiveType): List<File> {
        return listOf(
            File(archivesDirectory(), type.archiveFileName),
            File(rootDirectory, type.archiveFileName),
            File(rootDirectory, type.legacyArchiveFileName),
        )
    }

    private fun archivesDirectory(): File = File(rootDirectory, "archives")

    private fun clipsDirectory(): File = File(rootDirectory, "clips")

    companion object {
        const val ROOT_DIRECTORY_NAME = "offline_audio"
    }
}

internal interface AudioPlaybackController {
    fun play(clipFile: File, clipKey: String)
}

internal class MediaPlayerAudioPlaybackController : AudioPlaybackController {
    private var mediaPlayer: MediaPlayer? = null
    private var activeClipKey: String? = null

    @Synchronized
    override fun play(clipFile: File, clipKey: String) {
        if (activeClipKey == clipKey) {
            releaseActivePlayerLocked()
            return
        }

        releaseActivePlayerLocked()
        val nextPlayer = MediaPlayer()
        try {
            nextPlayer.setDataSource(clipFile.absolutePath)
            nextPlayer.setOnCompletionListener { completedPlayer ->
                synchronized(this) {
                    if (mediaPlayer === completedPlayer) {
                        completedPlayer.release()
                        mediaPlayer = null
                        activeClipKey = null
                    }
                }
            }
            nextPlayer.prepare()
            nextPlayer.start()
            mediaPlayer = nextPlayer
            activeClipKey = clipKey
        } catch (error: Exception) {
            nextPlayer.release()
            throw error
        }
    }

    @Synchronized
    private fun releaseActivePlayerLocked() {
        mediaPlayer?.stop()
        mediaPlayer?.reset()
        mediaPlayer?.release()
        mediaPlayer = null
        activeClipKey = null
    }
}

internal class StoredZipAudioIndexer {
    fun buildIndex(archiveFile: File): Map<String, StoredZipEntryLocation> {
        val endOfCentralDirectory = readEndOfCentralDirectory(archiveFile)
        RandomAccessFile(archiveFile, "r").use { archive ->
            archive.seek(endOfCentralDirectory.centralDirectoryOffset)
            val directoryBytes = ByteArray(endOfCentralDirectory.centralDirectorySize.toInt())
            archive.readFully(directoryBytes)

            var cursor = 0
            val entries = mutableMapOf<String, StoredZipEntryLocation>()
            while (cursor + 46 <= directoryBytes.size) {
                if (readUInt32(directoryBytes, cursor) != 0x02014b50L) {
                    break
                }

                val compressionMethod = readUInt16(directoryBytes, cursor + 10)
                val compressedSize = readUInt32(directoryBytes, cursor + 20)
                val fileNameLength = readUInt16(directoryBytes, cursor + 28)
                val extraLength = readUInt16(directoryBytes, cursor + 30)
                val commentLength = readUInt16(directoryBytes, cursor + 32)
                val localHeaderOffset = readUInt32(directoryBytes, cursor + 42)
                val nameStart = cursor + 46
                val nameEnd = nameStart + fileNameLength
                val fileName = directoryBytes.copyOfRange(nameStart, nameEnd).toString(Charsets.UTF_8)

                if (compressionMethod != 0) {
                    throw StoredZipEntryFormatException(fileName)
                }

                val clipId = clipIdFromPath(fileName)
                if (clipId.isNotEmpty()) {
                    entries[clipId] = StoredZipEntryLocation(
                        localHeaderOffset = localHeaderOffset,
                        size = compressedSize,
                    )
                }

                cursor = nameEnd + extraLength + commentLength
            }

            return entries
        }
    }

    fun materializeEntry(
        archiveFile: File,
        outputFile: File,
        entry: StoredZipEntryLocation,
    ): File {
        if (outputFile.exists() && outputFile.length() == entry.size) {
            return outputFile
        }

        outputFile.parentFile?.mkdirs()
        RandomAccessFile(archiveFile, "r").use { archive ->
            archive.seek(entry.localHeaderOffset)
            val localHeader = ByteArray(30)
            archive.readFully(localHeader)
            if (readUInt32(localHeader, 0) != 0x04034b50L) {
                throw ZipLocalHeaderFormatException()
            }

            val fileNameLength = readUInt16(localHeader, 26)
            val extraLength = readUInt16(localHeader, 28)
            val dataOffset = entry.localHeaderOffset + 30 + fileNameLength + extraLength
            archive.seek(dataOffset)

            outputFile.outputStream().use { output ->
                val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
                var remaining = entry.size
                while (remaining > 0) {
                    val bytesToRead = minOf(buffer.size.toLong(), remaining).toInt()
                    val bytesRead = archive.read(buffer, 0, bytesToRead)
                    if (bytesRead <= 0) {
                        throw IOException("Unexpected end of archive while materializing clip.")
                    }
                    output.write(buffer, 0, bytesRead)
                    remaining -= bytesRead.toLong()
                }
            }
        }

        return outputFile
    }

    private fun readEndOfCentralDirectory(archiveFile: File): EndOfCentralDirectory {
        val archiveLength = archiveFile.length()
        val tailLength = minOf(archiveLength, 65557L).toInt()

        RandomAccessFile(archiveFile, "r").use { archive ->
            archive.seek(archiveLength - tailLength)
            val tail = ByteArray(tailLength)
            archive.readFully(tail)

            for (cursor in tail.size - 22 downTo 0) {
                if (readUInt32(tail, cursor) == 0x06054b50L) {
                    return EndOfCentralDirectory(
                        centralDirectorySize = readUInt32(tail, cursor + 12),
                        centralDirectoryOffset = readUInt32(tail, cursor + 16),
                    )
                }
            }
        }

        throw ZipIndexNotFoundException()
    }

    private fun readUInt16(bytes: ByteArray, offset: Int): Int {
        return (bytes[offset].toInt() and 0xff) or
            ((bytes[offset + 1].toInt() and 0xff) shl 8)
    }

    private fun readUInt32(bytes: ByteArray, offset: Int): Long {
        return readUInt16(bytes, offset).toLong() or
            (readUInt16(bytes, offset + 2).toLong() shl 16)
    }

    private fun clipIdFromPath(path: String): String {
        val slashIndex = path.lastIndexOf('/')
        val dotIndex = path.lastIndexOf('.')
        if (dotIndex <= slashIndex) {
            return ""
        }
        return path.substring(slashIndex + 1, dotIndex)
    }
}

internal data class EndOfCentralDirectory(
    val centralDirectorySize: Long,
    val centralDirectoryOffset: Long,
)

internal data class StoredZipEntryLocation(
    val localHeaderOffset: Long,
    val size: Long,
)

internal class StoredZipEntryFormatException(
    val fileName: String,
) : IOException("Zip entry is compressed instead of stored: $fileName")

internal class ZipLocalHeaderFormatException : IOException("Zip local header is invalid.")

internal class ZipIndexNotFoundException : IOException("Zip end of central directory was not found.")