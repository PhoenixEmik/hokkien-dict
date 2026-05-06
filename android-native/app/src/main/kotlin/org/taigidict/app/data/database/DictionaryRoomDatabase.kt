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
            return Room.databaseBuilder(
                context.applicationContext,
                DictionaryRoomDatabase::class.java,
                databaseFile.name,
            ).build()
        }
    }
}
