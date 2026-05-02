package org.taigidict.app.app

import android.app.Application

class TaigiDictApplication : Application() {
    val appContainer: AppContainer by lazy {
        AppContainer(applicationContext)
    }
}
