package org.taigidict.app.feature.info

import android.webkit.WebChromeClient
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material.icons.automirrored.outlined.MenuBook
import androidx.compose.material.icons.outlined.TextFields
import androidx.compose.material3.Card
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import org.taigidict.app.R

private const val TailoGuideUrl = "https://sutian.moe.edu.tw/zh-hant/piantsip/tailo-phiautsu-suatbing/"
private const val HanjiGuideUrl = "https://sutian.moe.edu.tw/zh-hant/piantsip/hanji-iongji-guantsik/"

private val ReferenceHorizontalPadding = 16.dp
private val ReferenceVerticalPadding = 16.dp

private enum class ReferenceArticle(val titleRes: Int, val url: String) {
    Tailo(
        titleRes = R.string.about_tailo_title,
        url = TailoGuideUrl,
    ),
    Hanji(
        titleRes = R.string.about_hanji_title,
        url = HanjiGuideUrl,
    ),
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ReferenceArticleScreen(
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    var selectedArticle by rememberSaveable { mutableStateOf<ReferenceArticle?>(null) }

    val article = selectedArticle
    if (article != null) {
        BackHandler { selectedArticle = null }
        ReferenceWebPageScreen(
            title = stringResource(article.titleRes),
            url = article.url,
            onBack = { selectedArticle = null },
            modifier = modifier,
        )
        return
    }

    Scaffold(
        modifier = modifier,
        contentWindowInsets = WindowInsets.safeDrawing.only(
            WindowInsetsSides.Horizontal + WindowInsetsSides.Top,
        ),
        topBar = {
            TopAppBar(
                title = { Text(text = stringResource(R.string.settings_info_reference)) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Outlined.ArrowBack,
                            contentDescription = stringResource(R.string.settings_info_back),
                        )
                    }
                },
            )
        },
    ) { innerPadding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(horizontal = ReferenceHorizontalPadding)
                .padding(top = ReferenceVerticalPadding, bottom = ReferenceVerticalPadding),
            verticalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            item {
                Text(
                    text = stringResource(R.string.settings_info_reference),
                    style = MaterialTheme.typography.titleMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }

            item {
                Card {
                    Column(modifier = Modifier.fillMaxWidth()) {
                        ReferenceNavRow(
                            icon = Icons.AutoMirrored.Outlined.MenuBook,
                            title = stringResource(R.string.about_tailo_title),
                            onClick = { selectedArticle = ReferenceArticle.Tailo },
                        )
                        HorizontalDivider(
                            modifier = Modifier.padding(horizontal = 16.dp),
                            thickness = 0.5.dp,
                        )
                        ReferenceNavRow(
                            icon = Icons.Outlined.TextFields,
                            title = stringResource(R.string.about_hanji_title),
                            onClick = { selectedArticle = ReferenceArticle.Hanji },
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun ReferenceNavRow(
    icon: ImageVector,
    title: String,
    onClick: () -> Unit,
) {
    ListItem(
        modifier = Modifier.clickable(onClick = onClick),
        leadingContent = {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary,
            )
        },
        headlineContent = { Text(text = title) },
        trailingContent = {
            Icon(
                imageVector = Icons.AutoMirrored.Outlined.KeyboardArrowRight,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        },
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun ReferenceWebPageScreen(
    title: String,
    url: String,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
) {
    var progress by remember { mutableIntStateOf(0) }

    Scaffold(
        modifier = modifier,
        contentWindowInsets = WindowInsets.safeDrawing.only(
            WindowInsetsSides.Horizontal + WindowInsetsSides.Top,
        ),
        topBar = {
            TopAppBar(
                title = { Text(text = title) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Outlined.ArrowBack,
                            contentDescription = stringResource(R.string.settings_info_back),
                        )
                    }
                },
            )
        },
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding),
        ) {
            if (progress in 0..99) {
                androidx.compose.material3.LinearProgressIndicator(
                    progress = { progress / 100f },
                    modifier = Modifier.fillMaxWidth(),
                )
            }

            AndroidView(
                modifier = Modifier.fillMaxSize(),
                factory = { context ->
                    WebView(context).apply {
                        webViewClient = WebViewClient()
                        webChromeClient = object : WebChromeClient() {
                            override fun onProgressChanged(view: WebView?, newProgress: Int) {
                                progress = newProgress
                            }
                        }
                        settings.loadsImagesAutomatically = true
                        loadUrl(url)
                    }
                },
                update = { webView ->
                    if (webView.url != url) {
                        webView.loadUrl(url)
                    }
                },
            )
        }
    }
}