package org.taigidict.app.data.search

import android.content.Context
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

interface SearchHistoryStoring {
    val recentQueries: StateFlow<List<String>>

    fun addQuery(query: String)

    fun clear()
}

class SearchHistoryStore(
    context: Context,
    preferencesName: String = DEFAULT_PREFERENCES_NAME,
    storageKey: String = DEFAULT_STORAGE_KEY,
    private val maxEntries: Int = DEFAULT_MAX_ENTRIES,
) : SearchHistoryStoring {
    private val preferences = context.applicationContext
        .getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
    private val _recentQueries = MutableStateFlow(readQueries(storageKey))

    override val recentQueries: StateFlow<List<String>> = _recentQueries.asStateFlow()

    private val storageKey = storageKey

    override fun addQuery(query: String) {
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

        writeQueries(updated)
    }

    override fun clear() {
        writeQueries(emptyList())
    }

    private fun readQueries(key: String): List<String> {
        val rawValue = preferences.getString(key, null).orEmpty()
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

    private fun writeQueries(queries: List<String>) {
        preferences.edit()
            .putString(storageKey, queries.joinToString(separator = "\n"))
            .apply()
        _recentQueries.value = queries
    }

    companion object {
        private const val DEFAULT_PREFERENCES_NAME = "org.taigidict.app.search_history"
        private const val DEFAULT_STORAGE_KEY = "recent_search_queries"
        private const val DEFAULT_MAX_ENTRIES = 10
    }
}