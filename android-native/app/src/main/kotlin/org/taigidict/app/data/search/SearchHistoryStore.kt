package org.taigidict.app.data.search

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

interface SearchHistoryStoring {
    val recentQueries: StateFlow<List<String>>
    val hasLoaded: StateFlow<Boolean>

    suspend fun addQuery(query: String)

    suspend fun clear()
}

class SearchHistoryStore(
    context: Context,
    preferencesName: String = DEFAULT_PREFERENCES_NAME,
    storageKey: String = DEFAULT_STORAGE_KEY,
    private val maxEntries: Int = DEFAULT_MAX_ENTRIES,
    private val scope: CoroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.IO),
) : SearchHistoryStoring {
    private val storagePreferenceKey = stringPreferencesKey(storageKey)
    private val dataStore = PreferenceDataStoreFactory.create(
        migrations = listOf(SharedPreferencesMigration(context, preferencesName)),
        scope = scope,
        produceFile = {
            context.applicationContext.preferencesDataStoreFile(preferencesName)
        },
    )

    private val _recentQueries = MutableStateFlow(emptyList<String>())
    override val recentQueries: StateFlow<List<String>> = _recentQueries.asStateFlow()
    private val _hasLoaded = MutableStateFlow(false)
    override val hasLoaded: StateFlow<Boolean> = _hasLoaded.asStateFlow()

    init {
        scope.launch {
            dataStore.data
                .recoverPreferences()
                .map { preferences ->
                    readQueries(preferences[storagePreferenceKey].orEmpty())
                }
                .collect { queries ->
                    _recentQueries.value = queries
                    _hasLoaded.value = true
                }
        }
    }

    override suspend fun addQuery(query: String) {
        val normalized = query.trim().replace("\n", " ")
        if (normalized.isBlank()) {
            return
        }

        val updated = buildList {
            add(normalized)
            addAll(
                _recentQueries.value.filterNot {
                    it.equals(normalized, ignoreCase = true)
                },
            )
        }.take(maxEntries)

        dataStore.edit { preferences ->
            preferences[storagePreferenceKey] = serializeQueries(updated)
        }
        _recentQueries.value = updated
        _hasLoaded.value = true
    }

    override suspend fun clear() {
        dataStore.edit { preferences ->
            preferences[storagePreferenceKey] = ""
        }
        _recentQueries.value = emptyList()
        _hasLoaded.value = true
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

    private fun readQueries(rawValue: String): List<String> {
        if (rawValue.isBlank()) {
            return emptyList()
        }

        return rawValue
            .split("\n")
            .map { it.trim() }
            .filter { it.isNotBlank() }
            .fold(mutableListOf<String>()) { acc, value ->
                if (acc.none { it.equals(value, ignoreCase = true) }) {
                    acc.add(value)
                }
                acc
            }
    }

    private fun serializeQueries(queries: List<String>): String {
        return queries.joinToString(separator = "\n")
    }

    companion object {
        private const val DEFAULT_PREFERENCES_NAME = "org.taigidict.app.search_history"
        private const val DEFAULT_STORAGE_KEY = "recent_search_queries"
        private const val DEFAULT_MAX_ENTRIES = 10
    }
}
