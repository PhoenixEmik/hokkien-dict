package org.taigidict.app.data.bookmarks

import android.content.Context
import androidx.datastore.preferences.SharedPreferencesMigration
import androidx.datastore.preferences.core.PreferenceDataStoreFactory
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.emptyPreferences
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStoreFile
import java.io.IOException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch

class BookmarkStore(
    context: Context,
    preferencesName: String = DEFAULT_PREFERENCES_NAME,
    storageKey: String = DEFAULT_STORAGE_KEY,
    private val scope: CoroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.IO),
) {
    private val storagePreferenceKey = stringPreferencesKey(storageKey)
    private val dataStore = PreferenceDataStoreFactory.create(
        migrations = listOf(SharedPreferencesMigration(context, preferencesName)),
        scope = scope,
        produceFile = {
            context.applicationContext.preferencesDataStoreFile(preferencesName)
        },
    )

    private val _bookmarkedIds = MutableStateFlow(emptyList<Long>())
    val bookmarkedIds: StateFlow<List<Long>> = _bookmarkedIds.asStateFlow()

    init {
        scope.launch {
            dataStore.data
                .recoverPreferences()
                .map { preferences ->
                    readIds(preferences[storagePreferenceKey].orEmpty())
                }
                .collect { ids ->
                    _bookmarkedIds.value = ids
                }
        }
    }

    fun isBookmarked(entryId: Long): Boolean {
        return bookmarkedIds.value.contains(entryId)
    }

    suspend fun toggleBookmark(entryId: Long): Boolean {
        val updatedIds = _bookmarkedIds.value.toMutableList().apply {
            if (contains(entryId)) {
                remove(entryId)
            } else {
                remove(entryId)
                add(0, entryId)
            }
        }
        dataStore.edit { preferences ->
            preferences[storagePreferenceKey] = serializeIds(updatedIds)
        }
        _bookmarkedIds.value = updatedIds
        return updatedIds.contains(entryId)
    }

    suspend fun addBookmark(entryId: Long, index: Int = 0): Boolean {
        val updatedIds = _bookmarkedIds.value.toMutableList().apply {
            remove(entryId)
            add(index.coerceIn(0, size), entryId)
        }
        dataStore.edit { preferences ->
            preferences[storagePreferenceKey] = serializeIds(updatedIds)
        }
        _bookmarkedIds.value = updatedIds
        return true
    }

    suspend fun removeBookmark(entryId: Long): Boolean {
        val existingIds = _bookmarkedIds.value
        if (!existingIds.contains(entryId)) {
            return false
        }

        val updatedIds = existingIds.filterNot { it == entryId }
        dataStore.edit { preferences ->
            preferences[storagePreferenceKey] = serializeIds(updatedIds)
        }
        _bookmarkedIds.value = updatedIds
        return true
    }

    private fun Flow<Preferences>.recoverPreferences(): Flow<Preferences> {
        return catch { error ->
            if (error is IOException) {
                emit(emptyPreferences())
            } else {
                throw error
            }
        }
    }

    private fun readIds(rawValue: String): List<Long> {
        if (rawValue.isBlank()) {
            return emptyList()
        }

        return rawValue.split(',')
            .mapNotNull { token -> token.trim().toLongOrNull() }
            .distinct()
    }

    private fun serializeIds(ids: List<Long>): String {
        return ids.joinToString(separator = ",")
    }

    companion object {
        private const val DEFAULT_PREFERENCES_NAME = "org.taigidict.app.bookmarks"
        private const val DEFAULT_STORAGE_KEY = "bookmarked_entry_ids"
    }
}
