package org.taigidict.app.app

import android.app.Application

open class TaigiDictApplication : Application() {
    open fun createAppContainer(): AppContainer {
        return AppContainer(applicationContext)
    }

    open val appContainer: AppContainer by lazy {
        createAppContainer()
    }
}
