package org.taigidict.app.data.repository

import android.content.Context
import java.io.File

enum class DictionaryRepositoryBackend(val rawValue: String) {
    SQLite("sqlite"),
    Room("room");

    companion object {
        fun parse(rawValue: String): DictionaryRepositoryBackend {
            return entries.firstOrNull { backend ->
                backend.rawValue.equals(rawValue, ignoreCase = true)
            } ?: SQLite
        }
    }
}

object DictionaryRepositoryFactory {
    fun create(
        context: Context,
        databaseFile: File,
        backend: DictionaryRepositoryBackend,
    ): DictionaryRepositoryDataSource {
        return when (backend) {
            DictionaryRepositoryBackend.SQLite -> SQLiteDictionaryRepository(databaseFile = databaseFile)
            DictionaryRepositoryBackend.Room -> RoomDictionaryRepository(
                context = context,
                databaseFile = databaseFile,
            )
        }
    }
}
