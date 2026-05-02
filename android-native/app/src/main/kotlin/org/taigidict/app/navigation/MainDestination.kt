package org.taigidict.app.navigation

import androidx.annotation.StringRes
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Bookmarks
import androidx.compose.material.icons.outlined.MenuBook
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.ui.graphics.vector.ImageVector
import org.taigidict.app.R

enum class MainDestination(
    @StringRes val labelRes: Int,
    val icon: ImageVector,
) {
    Dictionary(R.string.tab_dictionary, Icons.Outlined.MenuBook),
    Bookmarks(R.string.tab_bookmarks, Icons.Outlined.Bookmarks),
    Settings(R.string.tab_settings, Icons.Outlined.Settings),
}
