package org.taigidict.app.data.database

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import java.io.File

@Database(
    entities = [
        DictionaryEntryEntity::class,
        DictionarySenseEntity::class,
        DictionaryExampleEntity::class,
        DictionaryMetadataEntity::class,
    ],
    version = 1,
    exportSchema = false,
)
abstract class DictionaryRoomDatabase : RoomDatabase() {
    abstract fun dictionaryDao(): DictionaryRoomDao

    companion object {
        fun open(context: Context, databaseFile: File): DictionaryRoomDatabase {
            val appDatabaseFile = context.applicationContext.getDatabasePath(databaseFile.name)
            val databaseName = if (databaseFile.absolutePath == appDatabaseFile.absolutePath) {
                databaseFile.name
            } else {
                "${databaseFile.nameWithoutExtension}-${databaseFile.absolutePath.hashCode()}.sqlite"
            }
            val builder = Room.databaseBuilder(
                context.applicationContext,
                DictionaryRoomDatabase::class.java,
                databaseName,
            )

            if (databaseFile.absolutePath != appDatabaseFile.absolutePath) {
                // Re-opening with a replaced source file should not keep stale copied DB content.
                context.applicationContext.deleteDatabase(databaseName)
                builder.createFromFile(databaseFile)
            }

            return builder
                .allowMainThreadQueries()
                .build()
        }
    }
}
