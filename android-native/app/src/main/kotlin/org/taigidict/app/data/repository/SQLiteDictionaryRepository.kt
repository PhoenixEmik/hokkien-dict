package org.taigidict.app.data.repository

import java.io.File
import org.taigidict.app.data.database.DictionaryDatabase
import org.taigidict.app.domain.model.DictionaryBundle

class SQLiteDictionaryRepository(
    private val databaseFile: File,
) {
    fun loadBundle(): DictionaryBundle {
        val metadata = DictionaryDatabase.readMetadata(databaseFile)
            ?: throw SQLiteDictionaryRepositoryException.MissingDatabase(databaseFile)

        val entryCount = metadata["entry_count"]?.toIntOrNull()
            ?: throw SQLiteDictionaryRepositoryException.MissingMetadata("entry_count")
        val senseCount = metadata["sense_count"]?.toIntOrNull()
            ?: throw SQLiteDictionaryRepositoryException.MissingMetadata("sense_count")
        val exampleCount = metadata["example_count"]?.toIntOrNull()
            ?: throw SQLiteDictionaryRepositoryException.MissingMetadata("example_count")

        return DictionaryBundle(
            entryCount = entryCount,
            senseCount = senseCount,
            exampleCount = exampleCount,
            databasePath = databaseFile.path,
        )
    }
}

sealed class SQLiteDictionaryRepositoryException(message: String) : Exception(message) {
    class MissingDatabase(file: File) :
        SQLiteDictionaryRepositoryException("Dictionary database is missing at ${file.path}.")

    class MissingMetadata(key: String) :
        SQLiteDictionaryRepositoryException("Dictionary metadata is missing key $key.")
}