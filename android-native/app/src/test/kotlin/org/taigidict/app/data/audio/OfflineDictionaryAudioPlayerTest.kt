package org.taigidict.app.data.audio

import java.io.ByteArrayOutputStream
import java.io.File
import java.nio.file.Files
import java.util.zip.CRC32
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.taigidict.app.domain.model.DictionaryEntry
import org.taigidict.app.domain.model.DictionaryExample
import org.taigidict.app.domain.model.DictionarySense

class OfflineDictionaryAudioPlayerTest {
    @Test
    fun playEntryAudio_withLocalStoredArchive_materializesClipAndStartsPlayback() = runTest {
        val rootDirectory = Files.createTempDirectory("offline-audio-test").toFile()
        val playbackController = RecordingAudioPlaybackController()
        val player = OfflineDictionaryAudioPlayer(
            filesDirectory = rootDirectory,
            playbackController = playbackController,
        )
        val archiveFile = File(
            File(File(rootDirectory, DictionaryAudioArchiveStorage.ROOT_DIRECTORY_NAME), "archives"),
            "sutiau-mp3.zip",
        )
        val clipBytes = "fake-mp3-entry".toByteArray()

        writeStoredZip(
            archiveFile = archiveFile,
            entries = mapOf(
                "word/1(1).mp3" to "validation".toByteArray(),
                "word/entry-1.mp3" to clipBytes,
            ),
        )

        val result = player.playEntryAudio(sampleEntry(audioId = "entry-1"))

        assertEquals(DictionaryAudioPlaybackResult.Played, result)
        assertEquals(
            DictionaryAudioPlaybackState.Playing("word:entry-1"),
            player.playbackState.value,
        )
        assertEquals("word:entry-1", playbackController.lastClipKey)
        assertTrue(playbackController.lastClipFile?.exists() == true)
        assertArrayEquals(clipBytes, playbackController.lastClipFile?.readBytes())
    }

    @Test
    fun playExampleAudio_withoutArchive_returnsUnavailableFailure() = runTest {
        val rootDirectory = Files.createTempDirectory("offline-audio-missing").toFile()
        val player = OfflineDictionaryAudioPlayer(
            filesDirectory = rootDirectory,
            playbackController = RecordingAudioPlaybackController(),
        )

        val result = player.playExampleAudio(
            DictionaryExample(
                hanji = "例句",
                romanization = "lē-kù",
                mandarin = "例句",
                audioId = "sentence-1",
            ),
        )

        assertEquals(
            DictionaryAudioPlaybackResult.Failed(DictionaryAudioPlaybackResult.FailureReason.ArchiveNotDownloaded),
            result,
        )
        assertEquals(DictionaryAudioPlaybackState.Idle, player.playbackState.value)
    }

    @Test
    fun playEntryAudio_withoutClipInArchive_resetsStateToIdle() = runTest {
        val rootDirectory = Files.createTempDirectory("offline-audio-missing-clip").toFile()
        val player = OfflineDictionaryAudioPlayer(
            filesDirectory = rootDirectory,
            playbackController = RecordingAudioPlaybackController(),
        )
        val archiveFile = File(
            File(File(rootDirectory, DictionaryAudioArchiveStorage.ROOT_DIRECTORY_NAME), "archives"),
            "sutiau-mp3.zip",
        )

        writeStoredZip(
            archiveFile = archiveFile,
            entries = mapOf(
                "word/1(1).mp3" to "validation".toByteArray(),
            ),
        )

        val result = player.playEntryAudio(sampleEntry(audioId = "missing-entry"))

        assertEquals(
            DictionaryAudioPlaybackResult.Failed(DictionaryAudioPlaybackResult.FailureReason.AudioClipNotFound),
            result,
        )
        assertEquals(DictionaryAudioPlaybackState.Idle, player.playbackState.value)
    }

    @Test
    fun playEntryAudio_withWhitespaceInAudioId_trimsAndPlays() = runTest {
        val rootDirectory = Files.createTempDirectory("offline-audio-trim").toFile()
        val playbackController = RecordingAudioPlaybackController()
        val player = OfflineDictionaryAudioPlayer(
            filesDirectory = rootDirectory,
            playbackController = playbackController,
        )
        val archiveFile = File(
            File(File(rootDirectory, DictionaryAudioArchiveStorage.ROOT_DIRECTORY_NAME), "archives"),
            "sutiau-mp3.zip",
        )
        val clipBytes = "fake-mp3-entry".toByteArray()

        writeStoredZip(
            archiveFile = archiveFile,
            entries = mapOf(
                "word/1(1).mp3" to "validation".toByteArray(),
                "word/entry-1.mp3" to clipBytes,
            ),
        )

        val result = player.playEntryAudio(sampleEntry(audioId = "  entry-1  "))

        assertEquals(DictionaryAudioPlaybackResult.Played, result)
        assertEquals(
            DictionaryAudioPlaybackState.Playing("word:entry-1"),
            player.playbackState.value,
        )
        assertEquals("word:entry-1", playbackController.lastClipKey)
        assertArrayEquals(clipBytes, playbackController.lastClipFile?.readBytes())
    }

    @Test
    fun playEntryAudio_sameClipAgain_stopsPlaybackAndResetsState() = runTest {
        val rootDirectory = Files.createTempDirectory("offline-audio-toggle").toFile()
        val playbackController = RecordingAudioPlaybackController()
        val player = OfflineDictionaryAudioPlayer(
            filesDirectory = rootDirectory,
            playbackController = playbackController,
        )
        val archiveFile = File(
            File(File(rootDirectory, DictionaryAudioArchiveStorage.ROOT_DIRECTORY_NAME), "archives"),
            "sutiau-mp3.zip",
        )

        writeStoredZip(
            archiveFile = archiveFile,
            entries = mapOf(
                "word/1(1).mp3" to "validation".toByteArray(),
                "word/entry-1.mp3" to "fake-mp3-entry".toByteArray(),
            ),
        )

        player.playEntryAudio(sampleEntry(audioId = "entry-1"))
        assertEquals(DictionaryAudioPlaybackState.Playing("word:entry-1"), player.playbackState.value)

        player.playEntryAudio(sampleEntry(audioId = "entry-1"))

        assertEquals(DictionaryAudioPlaybackState.Idle, player.playbackState.value)
    }

    @Test
    fun playbackCompletion_resetsStateToIdle() = runTest {
        val rootDirectory = Files.createTempDirectory("offline-audio-complete").toFile()
        val playbackController = RecordingAudioPlaybackController()
        val player = OfflineDictionaryAudioPlayer(
            filesDirectory = rootDirectory,
            playbackController = playbackController,
        )
        val archiveFile = File(
            File(File(rootDirectory, DictionaryAudioArchiveStorage.ROOT_DIRECTORY_NAME), "archives"),
            "sutiau-mp3.zip",
        )

        writeStoredZip(
            archiveFile = archiveFile,
            entries = mapOf(
                "word/1(1).mp3" to "validation".toByteArray(),
                "word/entry-1.mp3" to "fake-mp3-entry".toByteArray(),
            ),
        )

        player.playEntryAudio(sampleEntry(audioId = "entry-1"))
        playbackController.completePlayback()

        assertEquals(DictionaryAudioPlaybackState.Idle, player.playbackState.value)
    }
}

private class RecordingAudioPlaybackController : AudioPlaybackController {
    var lastClipFile: File? = null
    var lastClipKey: String? = null
    private var activeClipKey: String? = null
    private var onPlaybackCompleted: (() -> Unit)? = null

    override fun play(
        clipFile: File,
        clipKey: String,
        onPlaybackCompleted: () -> Unit,
    ): AudioPlaybackTransition {
        if (activeClipKey == clipKey) {
            activeClipKey = null
            this.onPlaybackCompleted = null
            return AudioPlaybackTransition.Stopped
        }
        lastClipFile = clipFile
        lastClipKey = clipKey
        activeClipKey = clipKey
        this.onPlaybackCompleted = onPlaybackCompleted
        return AudioPlaybackTransition.Started
    }

    fun completePlayback() {
        activeClipKey = null
        onPlaybackCompleted?.invoke()
        onPlaybackCompleted = null
    }
}

private fun writeStoredZip(
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

private fun sampleEntry(audioId: String): DictionaryEntry {
    return DictionaryEntry(
        id = 1,
        type = "名詞",
        hanji = "辭典",
        romanization = "sû-tián",
        category = "主詞目",
        audioId = audioId,
        hokkienSearch = "辭典 sû-tián",
        mandarinSearch = "辭典",
        variantChars = emptyList(),
        wordSynonyms = emptyList(),
        wordAntonyms = emptyList(),
        alternativePronunciations = emptyList(),
        contractedPronunciations = emptyList(),
        colloquialPronunciations = emptyList(),
        phoneticDifferences = emptyList(),
        vocabularyComparisons = emptyList(),
        aliasTargetEntryId = null,
        senses = listOf(
            DictionarySense(
                partOfSpeech = "名詞",
                definition = "一種工具書。",
                definitionSynonyms = emptyList(),
                definitionAntonyms = emptyList(),
                examples = emptyList(),
            ),
        ),
    )
}
