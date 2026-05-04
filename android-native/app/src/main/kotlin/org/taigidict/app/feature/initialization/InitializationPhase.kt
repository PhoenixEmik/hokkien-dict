package org.taigidict.app.feature.initialization

enum class InitializationPhase {
    CheckingResources,
    RestoringBundledSource,
    DownloadingSource,
    RebuildingDatabase,
    Ready,
    Error,
}
