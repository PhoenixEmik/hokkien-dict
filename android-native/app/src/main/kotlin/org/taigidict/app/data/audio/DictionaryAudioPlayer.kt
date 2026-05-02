package org.taigidict.app.data.audio

import org.taigidict.app.domain.model.DictionaryEntry
import org.taigidict.app.domain.model.DictionaryExample

sealed interface DictionaryAudioPlaybackResult {
    data object Played : DictionaryAudioPlaybackResult

    data class Failed(
        val reason: FailureReason,
    ) : DictionaryAudioPlaybackResult

    enum class FailureReason {
        MissingClipId,
        ArchiveNotDownloaded,
        AudioClipNotFound,
        AudioNotAvailable,
    }
}

interface DictionaryAudioPlayer {
    suspend fun playEntryAudio(entry: DictionaryEntry): DictionaryAudioPlaybackResult

    suspend fun playExampleAudio(example: DictionaryExample): DictionaryAudioPlaybackResult
}

class UnavailableDictionaryAudioPlayer : DictionaryAudioPlayer {
    override suspend fun playEntryAudio(entry: DictionaryEntry): DictionaryAudioPlaybackResult {
        return unavailableResult(entry.audioId)
    }

    override suspend fun playExampleAudio(example: DictionaryExample): DictionaryAudioPlaybackResult {
        return unavailableResult(example.audioId)
    }

    private fun unavailableResult(audioId: String): DictionaryAudioPlaybackResult {
        return if (audioId.isBlank()) {
            DictionaryAudioPlaybackResult.Failed(DictionaryAudioPlaybackResult.FailureReason.MissingClipId)
        } else {
            DictionaryAudioPlaybackResult.Failed(DictionaryAudioPlaybackResult.FailureReason.AudioNotAvailable)
        }
    }
}