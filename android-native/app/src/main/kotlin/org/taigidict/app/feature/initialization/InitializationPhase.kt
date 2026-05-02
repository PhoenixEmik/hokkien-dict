package org.taigidict.app.feature.initialization

enum class InitializationPhase {
    CheckingResources,
    RebuildingDatabase,
    Ready,
    Error,
}
