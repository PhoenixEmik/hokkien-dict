package org.taigidict.app.feature.info

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import org.taigidict.app.R
import java.util.Locale

@Composable
fun TailoGuideContent(modifier: Modifier = Modifier) {
    val locale = LocalConfiguration.current.locales[0]
    val appLocale = when {
        locale.language == "zh" && locale.country == "CN" -> "simplified"
        locale.language == "zh" -> "traditional"
        else -> "english"
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
    ) {
        when (appLocale) {
            "traditional" -> TailoGuideTradition()
            "simplified" -> TailoGuideSimplified()
            else -> TailoGuideEnglish()
        }
    }
}

@Composable
private fun TailoGuideTradition() {
    GuideHeading("臺灣台語羅馬字拼音方案")
    GuideParagraph(
        "本辭典採用教育部於民國 95 年 10 月 14 日公告之「臺灣台語羅馬字拼音方案（臺羅）」作為辭典的羅馬字系統。" +
                "辭典本文中之外來詞則以臺灣台語詞目視之，標注其回推之本調。"
    )

    GuideHeading("一般聲調", level = 2)
    GuideParagraph(
        "一般聲調分作第 1 聲、第 2 聲、第 3 聲、第 4 聲、第 5 聲、第 7 聲、第 8 聲。" +
                "漢語的聲調初分為平、上、去、入四種，而後各自再分陰、陽，但各方言在語言演進的過程中，產生不同的狀況。" +
                "今日臺灣台語的通行腔，陽上的調值已演變為和陽去是一樣的，因此共有七個聲調。"
    )
    GuideSubheading("常見對應示例")
    GuideTable(
        headers = listOf("漢語調類", "陰平", "陰上", "陰去", "陰入", "陽平", "陽去", "陽入"),
        rows = listOf(
            listOf("正式版", "tong", "tóng", "tòng", "tok", "tông", "tōng", "to̍k"),
            listOf("數字版", "tong1", "tong2", "tong3", "tok4", "tong5", "tong7", "tok8"),
            listOf("例字", "東", "黨", "棟", "督", "同", "洞", "毒"),
        ),
    )

    GuideHeading("特殊聲調", level = 2)
    GuideBulletList(
        listOf(
            "有些地方音有第 6 聲，如「ǒ」(數字版為 o6)。",
            "合音及三連音的第一音節有第 9 聲，如「ő」(數字版為 o9)。",
            "輕聲符號「--」標記在重聲與輕聲之間，輕聲符之前為重讀音節，唸本調，輕聲符之後為輕聲。例如：āu--ji̍t（後--日）、tsáu--tshut-khì（走--出去）。",
        ),
    )

    GuideHeading("變調", level = 2)
    GuideParagraph(
        "在詞句中有「連讀變調」，即單字的語音會因為接了另一個字而改變聲調，使句中的字音與該單字的本調聽起來不同。" +
                "不過句子裡有幾種情況例外，當語氣完結、所接的字為弱讀調、主語被凸顯等情況之下，即使在句中也不變調。"
    )
    GuideSubheading("主流變調規則")
    GuideTable(
        headers = listOf("本調", "變調", "例詞", "本調讀音", "變調讀音"),
        rows = listOf(
            listOf("第 1 聲", "1→7", "心肝", "sim-kuann", "sīm-kuann"),
            listOf("第 2 聲", "2→1", "小弟", "sió-tī", "sio-tī"),
            listOf("第 3 聲", "3→2", "世間", "sè-kan", "sé-kan"),
            listOf("第 4 聲", "4→8（-p/-t/-k）", "出名", "tshut-miâ", "tshu̍t-miâ"),
            listOf("第 4 聲", "4→2（-h）", "鐵馬", "thih-bé", "thí-bé"),
            listOf("第 5 聲", "5→7（漳）", "來往", "lâi-óng", "lāi-óng"),
            listOf("第 5 聲", "5→3（泉）", "來往", "lâi-óng", "lài-óng"),
            listOf("第 7 聲", "7→3", "外口", "guā-kháu", "guà-kháu"),
            listOf("第 8 聲", "8→4（-p/-t/-k）", "木瓜", "bo̍k-kue", "bok-kue"),
            listOf("第 8 聲", "8→3（-h）", "月娘", "gue̍h-niû", "guè-niû"),
        ),
    )
    GuideParagraph(
        "由於變調的情況會隨著斷句而改變，而斷句的方式不止有一種，因此，本辭典的聲調皆標注本調，不標變調。" +
                "但輕聲調會隨語境的需要以「--」標注，而詞目主音讀除非是沒有本調的唸法，否則也都標注本調。"
    )

    GuideHeading("無聲調標注", level = 2)
    GuideParagraph(
        "語助詞、感嘆詞、語法詞等沒有固定聲調的字，依書寫習用以第 4 聲喉塞尾「-h」標注之，" +
                "而因其為輕讀，不影響前字的變調，故依臺灣台語羅馬字拼音方案，加上表示輕聲的「--」，例如："
    )
    GuideBulletList(
        listOf(
            "--lah（啦）",
            "--aih（哎）",
            "--ooh（喔）",
            "--ah（啊）",
        ),
    )
}

@Composable
private fun TailoGuideSimplified() {
    GuideHeading("台湾台语罗马字拼音方案")
    GuideParagraph(
        "本辞典采用教育部于民国 95 年 10 月 14 日公告之「台湾台语罗马字拼音方案（台罗）」作为辞典的罗马字系统。" +
                "辞典本文中之外来词则以台湾台语词目视之，标注其回推之本调。"
    )

    GuideHeading("一般声调", level = 2)
    GuideParagraph(
        "一般声调分作第 1 声、第 2 声、第 3 声、第 4 声、第 5 声、第 7 声、第 8 声。" +
                "汉语的声调初分为平、上、去、入四种，而后各自再分阴、阳，但各方言在语言演进的过程中，产生不同的状况。" +
                "今日台湾台语的通行腔，阳上的调值已演变为和阳去是一样的，因此共有七个声调。"
    )
    GuideSubheading("常见对应示例")
    GuideTable(
        headers = listOf("汉语调类", "阴平", "阴上", "阴去", "阴入", "阳平", "阳去", "阳入"),
        rows = listOf(
            listOf("正式版", "tong", "tóng", "tòng", "tok", "tông", "tōng", "to̍k"),
            listOf("数字版", "tong1", "tong2", "tong3", "tok4", "tong5", "tong7", "tok8"),
            listOf("例字", "东", "党", "栋", "督", "同", "洞", "毒"),
        ),
    )

    GuideHeading("特殊声调", level = 2)
    GuideBulletList(
        listOf(
            "有些地方音有第 6 声，如「ǒ」(数字版为 o6)。",
            "合音及三连音的第一音节有第 9 声，如「ő」(数字版为 o9)。",
            "轻声符号「--」标记在重声与轻声之间，轻声符之前为重读音节，唸本调，轻声符之后为轻声。例如：āu--ji̍t（后--日）、tsáu--tshut-khì（走--出去）。",
        ),
    )

    GuideHeading("变调", level = 2)
    GuideParagraph(
        "在词句中有「连读变调」，即单字的语音会因为接了另一个字而改变声调，使句中的字音与该单字的本调听起来不同。" +
                "不过句子里有几种情况例外，当语气完结、所接的字为弱读调、主语被凸显等情况之下，即使在句中也不变调。"
    )
    GuideSubheading("主流变调规则")
    GuideTable(
        headers = listOf("本调", "变调", "例词", "本调读音", "变调读音"),
        rows = listOf(
            listOf("第 1 声", "1→7", "心肝", "sim-kuann", "sīm-kuann"),
            listOf("第 2 声", "2→1", "小弟", "sió-tī", "sio-tī"),
            listOf("第 3 声", "3→2", "世间", "sè-kan", "sé-kan"),
            listOf("第 4 声", "4→8（-p/-t/-k）", "出名", "tshut-miâ", "tshu̍t-miâ"),
            listOf("第 4 声", "4→2（-h）", "铁马", "thih-bé", "thí-bé"),
            listOf("第 5 声", "5→7（漳）", "来往", "lâi-óng", "lāi-óng"),
            listOf("第 5 声", "5→3（泉）", "来往", "lâi-óng", "lài-óng"),
            listOf("第 7 声", "7→3", "外口", "guā-kháu", "guà-kháu"),
            listOf("第 8 声", "8→4（-p/-t/-k）", "木瓜", "bo̍k-kue", "bok-kue"),
            listOf("第 8 声", "8→3（-h）", "月娘", "gue̍h-niû", "guè-niû"),
        ),
    )
    GuideParagraph(
        "由于变调的情况会随着断句而改变，而断句的方式不止有一种，因此，本辞典的声调皆标注本调，不标变调。" +
                "但轻声调会随语境的需要以「--」标注，而词目主音读除非是没有本调的唸法，否则也都标注本调。"
    )

    GuideHeading("无声调标注", level = 2)
    GuideParagraph(
        "语助词、感叹词、语法词等没有固定声调的字，依书写习用以第 4 声喉塞尾「-h」标注之，" +
                "而因其为轻读，不影响前字的变调，故依台湾台语罗马字拼音方案，加上表示轻声的「--」，例如："
    )
    GuideBulletList(
        listOf(
            "--lah（啦）",
            "--aih（哎）",
            "--ooh（喔）",
            "--ah（啊）",
        ),
    )
}

@Composable
private fun TailoGuideEnglish() {
    GuideHeading("Taiwanese Hokkien Romanization Scheme")
    GuideParagraph(
        "This dictionary uses the \"Taiwanese Hokkien Romanization Scheme (Tailo)\" announced by the Ministry of Education on October 14, 2006, " +
                "as its romanization system. Foreign words in the dictionary text are treated as Taiwanese Hokkien entries and marked with their original (non-sandhi) tone."
    )

    GuideHeading("Common Tones", level = 2)
    GuideParagraph(
        "Common tones are classified as Tone 1, 2, 3, 4, 5, 7, and 8. " +
                "In the initial classification of Mandarin Chinese, tones are divided into four categories (level, rising, departing, entering), " +
                "each further subdivided into yin (high) and yang (low). However, various dialects have undergone different evolutionary processes. " +
                "In modern standard Taiwanese Hokkien, the yang rising tone has evolved to become identical to the yang departing tone, resulting in a total of seven tones."
    )
    GuideSubheading("Common Correspondences")
    GuideTable(
        headers = listOf("Tone Class", "High-level", "High-rising", "High-departing", "High-entering", "Low-level", "Low-departing", "Low-entering"),
        rows = listOf(
            listOf("Formal", "tong", "tóng", "tòng", "tok", "tông", "tōng", "to̍k"),
            listOf("Numeric", "tong1", "tong2", "tong3", "tok4", "tong5", "tong7", "tok8"),
            listOf("Example", "east", "party", "ridge", "supervise", "same", "cave", "poison"),
        ),
    )

    GuideHeading("Special Tones", level = 2)
    GuideBulletList(
        listOf(
            "Some dialect variations have Tone 6, for example: \"ǒ\" (numeric: o6).",
            "The first syllable of combined sounds and three-syllable sequences may have Tone 9, for example: \"ő\" (numeric: o9).",
            "The light-tone mark \"--\" is placed between a stressed syllable and a light-tone syllable. For example: āu--ji̍t (back--day), tsáu--tshut-khì (run--exit).",
        ),
    )

    GuideHeading("Tone Sandhi", level = 2)
    GuideParagraph(
        "In phrases and sentences, \"tone sandhi\" occurs, where a character's tone changes when followed by another character. " +
                "However, there are exceptions: when the phrase ends, when the following syllable is in a weak tone, or when the subject is emphasized, " +
                "the original tone may be maintained even within a sentence."
    )
    GuideSubheading("Main Tone Sandhi Rules")
    GuideTable(
        headers = listOf("Base Tone", "Sandhi", "Example", "Base Pronunciation", "Sandhi Pronunciation"),
        rows = listOf(
            listOf("Tone 1", "1→7", "heart-liver", "sim-kuann", "sīm-kuann"),
            listOf("Tone 2", "2→1", "young-brother", "sió-tī", "sio-tī"),
            listOf("Tone 3", "3→2", "world-time", "sè-kan", "sé-kan"),
            listOf("Tone 4", "4→8 (-p/-t/-k)", "emerge-name", "tshut-miâ", "tshu̍t-miâ"),
            listOf("Tone 4", "4→2 (-h)", "iron-horse", "thih-bé", "thí-bé"),
            listOf("Tone 5", "5→7 (Zhangzhou)", "come-go", "lâi-óng", "lāi-óng"),
            listOf("Tone 5", "5→3 (Quanzhou)", "come-go", "lâi-óng", "lài-óng"),
            listOf("Tone 7", "7→3", "outside-mouth", "guā-kháu", "guà-kháu"),
            listOf("Tone 8", "8→4 (-p/-t/-k)", "wood-melon", "bo̍k-kue", "bok-kue"),
            listOf("Tone 8", "8→3 (-h)", "moon-lady", "gue̍h-niû", "guè-niû"),
        ),
    )
    GuideParagraph(
        "Because tone sandhi varies depending on how phrases are segmented, and segmentation can be done in multiple ways, " +
                "this dictionary marks all tones as original tones without indicating sandhi changes. " +
                "However, light tones are marked with \"--\" as needed according to context."
    )

    GuideHeading("Toneless Marks", level = 2)
    GuideParagraph(
        "Particles, exclamations, and grammatical words without fixed tones are conventionally written with a glottal stop \"-h\" from Tone 4. " +
                "Since these are typically read lightly and do not affect tone sandhi in the preceding character, " +
                "the light-tone mark \"--\" is added according to the Taiwanese Hokkien Romanization Scheme:"
    )
    GuideBulletList(
        listOf(
            "--lah (particle)",
            "--aih (exclamation)",
            "--ooh (exclamation)",
            "--ah (particle)",
        ),
    )
}

@Composable
private fun GuideHeading(text: String, level: Int = 1) {
    val style = when (level) {
        1 -> MaterialTheme.typography.headlineSmall
        else -> MaterialTheme.typography.titleMedium
    }
    Text(
        text = text,
        style = style,
        fontWeight = FontWeight.Bold,
        modifier = Modifier.padding(top = if (level == 1) 0.dp else 12.dp, bottom = 8.dp),
    )
}

@Composable
private fun GuideSubheading(text: String) {
    Text(
        text = text,
        style = MaterialTheme.typography.titleSmall,
        fontWeight = FontWeight.SemiBold,
        modifier = Modifier.padding(top = 8.dp, bottom = 6.dp),
        color = MaterialTheme.colorScheme.onSurfaceVariant,
    )
}

@Composable
private fun GuideParagraph(text: String) {
    Text(
        text = text,
        style = MaterialTheme.typography.bodyMedium,
        modifier = Modifier.padding(vertical = 6.dp),
        color = MaterialTheme.colorScheme.onSurface,
    )
}

@Composable
private fun GuideBulletList(items: List<String>) {
    Column(modifier = Modifier.padding(vertical = 8.dp)) {
        items.forEach { item ->
            Text(
                text = "• $item",
                style = MaterialTheme.typography.bodyMedium,
                modifier = Modifier.padding(vertical = 4.dp),
                color = MaterialTheme.colorScheme.onSurface,
            )
        }
    }
}

@Composable
private fun GuideTable(headers: List<String>, rows: List<List<String>>) {
    Column(modifier = Modifier.padding(vertical = 8.dp)) {
        // Header row
        Row(headers = headers)
        Column(modifier = Modifier.padding(vertical = 4.dp)) {
            rows.forEach { row ->
                Row(headers = row)
            }
        }
    }
}

@Composable
private fun Row(headers: List<String>) {
    Text(
        text = headers.joinToString(" | "),
        style = MaterialTheme.typography.labelSmall,
        modifier = Modifier.padding(4.dp),
        color = MaterialTheme.colorScheme.onSurfaceVariant,
    )
}
