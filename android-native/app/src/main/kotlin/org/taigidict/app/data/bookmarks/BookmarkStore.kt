package org.taigidict.app.data.bookmarks

import android.content.Context
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

class BookmarkStore(
    context: Context,
    preferencesName: String = DEFAULT_PREFERENCES_NAME,
    storageKey: String = DEFAULT_STORAGE_KEY,
) {
    private val preferences = context.applicationContext.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
    private val _bookmarkedIds = MutableStateFlow(readIds(storageKey))

    val bookmarkedIds: StateFlow<List<Long>> = _bookmarkedIds.asStateFlow()

    private val storageKey = storageKey

    fun isBookmarked(entryId: Long): Boolean {
        return _bookmarkedIds.value.contains(entryId)
    }

    fun toggleBookmark(entryId: Long): Boolean {
        val updatedIds = _bookmarkedIds.value.toMutableList().apply {
            if (contains(entryId)) {
                remove(entryId)
            } else {
                remove(entryId)
                add(0, entryId)
            }
        }
        writeIds(updatedIds)
        return updatedIds.contains(entryId)
    }

    fun removeBookmark(entryId: Long): Boolean {
        if (!_bookmarkedIds.value.contains(entryId)) {
            return false
        }

        val updatedIds = _bookmarkedIds.value.filterNot { it == entryId }
        writeIds(updatedIds)
        return true
    }

    private fun readIds(key: String): List<Long> {
        val rawValue = preferences.getString(key, null).orEmpty()
        if (rawValue.isBlank()) {
            return emptyList()
        }

        return rawValue.split(',')
            .mapNotNull { token -> token.trim().toLongOrNull() }
            .distinct()
    }

    private fun writeIds(ids: List<Long>) {
        preferences.edit()
            .putString(storageKey, ids.joinToString(separator = ","))
            .apply()
        _bookmarkedIds.value = ids
    }

    companion object {
        private const val DEFAULT_PREFERENCES_NAME = "org.taigidict.app.bookmarks"
        private const val DEFAULT_STORAGE_KEY = "bookmarked_entry_ids"
    }
}