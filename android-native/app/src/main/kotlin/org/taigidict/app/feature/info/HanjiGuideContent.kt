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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp

@Composable
fun HanjiGuideContent(modifier: Modifier = Modifier) {
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
            "traditional" -> HanjiGuideTradition()
            "simplified" -> HanjiGuideSimplified()
            else -> HanjiGuideEnglish()
        }
    }
}

@Composable
private fun HanjiGuideTradition() {
    GuideHeading("漢字用字原則")
    GuideParagraph(
        "本頁整理教育部《教育部臺灣台語常用詞辭典》對台語漢字書寫的核心原則，作為 App 內閱讀版本。"
    )

    GuideHeading("漢字狀況", level = 2)
    GuideParagraph(
        "臺灣台語與華語在語音、詞彙、句法上本有許多差異。又由於分支較早，彼此間的差異亦相當顯著，書寫方面的問題與爭議較多。" +
                "百多年來通行的各家詞書，在用字上各有所選擇，但對「本字」的認定則差異不大，學者們的考證也在逐漸累積可信的本字。" +
                "但其中仍有許多來源不明的字、詞，根本非源於漢語，造成「有音無字」問題。"
    )

    GuideHeading("本辭典用字類型", level = 2)
    GuideParagraph(
        "在各種書寫方式中，本辭典以漢字為基礎，採「一音一漢字」。而選字的標準，則依該字的使用現況，再據本典既定的概念選定用字。大致有以下三種類型："
    )

    GuideSubheading("1. 本字")
    GuideParagraph(
        "相對於「訓用字」、「借音字」、「新造字」而言。指在傳統文獻中即有漢字字形，且意義與臺灣台語詞彙具同源關係的用字。"
    )
    GuideBulletList(
        listOf(
            "例：表示「香」的 phang 本字為【芳】",
            "例：表示「小」的 sè 本字為【細】",
        ),
    )

    GuideSubheading("2. 訓用字")
    GuideParagraph(
        "使用詞義相同的漢字字形，來表現相對應這個詞義的臺灣台語音讀。從用字來說，是借義不借音，" +
                "即取所用字形之義，加上去的音讀則另有本字。"
    )
    GuideBulletList(
        listOf(
            "例：【人】的字形臺灣台語讀 jîn，而表示「人」有另一說法是 lâng，本字當作【農】或【儂】，" +
                    "但本辭典皆定【人】為用字，讀 lâng 時即為訓用字。" +
                    "如：【人生】jîn-sing 之「人」，讀 jîn；另在【人去】lâng-khì 之「人」則讀 lâng，屬訓用字。",
        ),
    )

    GuideSubheading("3. 俗字、借音字與新造字")
    GuideParagraph("俗字/借音字：指一般民間或出自文獻的用字，有些是借某漢字的臺灣台語音讀，直接表達一個音同或音近但詞義不同的詞彙。")
    GuideBulletList(listOf("例：【某】臺灣台語讀 bóo，可表「妻子」義"))

    GuideParagraph("新造字：當音讀與詞義都找不到可以使用的漢字時，便需要創造新字。造字原理多為形聲，次為會意。")
    GuideBulletList(
        listOf(
            "例：表示「爬、攀登」的【𬦰】peh（形聲）",
            "例：表示「長得高」的【躼】lò（會意）",
        ),
    )

    GuideHeading("替代字說明", level = 2)
    GuideParagraph(
        "非本字之用字，本辭典稱為「替代字」，故前述「訓用字」、「俗字」、「借音字」、「新造字」等都是替代字。" +
                "在用字選擇上，我們傾向使用本字，但有以下幾種情況，即使本字確定，權衡之下還是有可能會捨棄本字："
    )

    GuideSubheading("1. 本字過於艱深晦澀")
    GuideParagraph("本字過於艱深晦澀，一般大眾極不熟悉者。")
    GuideBulletList(listOf("例：表示「耕作之地」的 tshân 本字為【塍】，但我們選擇用【田】字來表示。"))

    GuideSubheading("2. 字義與標準語相同且為基本字")
    GuideParagraph("該字字義與對應的標準語用字完全相同，且為極常用的基本字，用本字反而容易造成閱讀上的困擾者。")
    GuideBulletList(listOf("例：「人」讀作 lâng 的本字為【農】或【儂】，但我們選擇用【人】字來替代。"))

    GuideSubheading("3. 約定俗成的俗字")
    GuideParagraph("幾乎已經約定俗成、使用也很廣泛的俗字，不易改變使用習慣者。")
    GuideBulletList(listOf("例：表示「宰殺」的 thâi 本字是【治】，我們選擇使用俗字【刣】來表示。"))

    GuideParagraph(
        "在選字上我們希望能夠「望字生音義」，讓讀者通過該字的形或音而聯想到書寫者想要表達的概念。" +
                "如表示「低窪泥濘」的 làm 有「坔」和「湳」兩種書寫形式，其中「坔」是會意字，而「湳」是形聲字，" +
                "如果是這兩個字來做比較，我們會選擇用「湳」，因為形聲字的表音功能和意義的聯繫比較緊密。"
    )

    GuideHeading("推薦用字", level = 2)
    GuideParagraph(
        "教育部分別於民國 96 年及 97 年公告「臺灣台語推薦用字」共計 700 字詞，本辭典原則上遵照推薦用字之成果。"
    )
}

@Composable
private fun HanjiGuideSimplified() {
    GuideHeading("汉字用字原则")
    GuideParagraph(
        "本页整理教育部《教育部台湾台语常用词辞典》对台语汉字书写的核心原则，作为 App 内阅读版本。"
    )

    GuideHeading("汉字状况", level = 2)
    GuideParagraph(
        "台湾台语与华语在语音、词汇、句法上本有许多差异。又由于分支较早，彼此间的差异亦相当显著，书写方面的问题与争议较多。" +
                "百多年来通行的各家词书，在用字上各有所选择，但对「本字」的认定则差异不大，学者们的考证也在逐渐累积可信的本字。" +
                "但其中仍有许多来源不明的字、词，根本非源于汉语，造成「有音无字」问题。"
    )

    GuideHeading("本辞典用字类型", level = 2)
    GuideParagraph(
        "在各种书写方式中，本辞典以汉字为基础，采「一音一汉字」。而选字的标准，则依该字的使用现况，再据本典既定的概念选定用字。大致有以下三种类型："
    )

    GuideSubheading("1. 本字")
    GuideParagraph(
        "相对于「训用字」、「借音字」、「新造字」而言。指在传统文献中即有汉字字形，且意义与台湾台语词汇具同源关系的用字。"
    )
    GuideBulletList(
        listOf(
            "例：表示「香」的 phang 本字为【芳】",
            "例：表示「小」的 sè 本字为【细】",
        ),
    )

    GuideSubheading("2. 训用字")
    GuideParagraph(
        "使用词义相同的汉字字形，来表现相对应这个词义的台湾台语音读。从用字来说，是借义不借音，" +
                "即取所用字形之义，加上去的音读则另有本字。"
    )
    GuideBulletList(
        listOf(
            "例：【人】的字形台湾台语读 jîn，而表示「人」有另一说法是 lâng，本字当作【农】或【儂】，" +
                    "但本辞典皆定【人】为用字，读 lâng 时即为训用字。" +
                    "如：【人生】jîn-sing 之「人」，读 jîn；另在【人去】lâng-khì 之「人」则读 lâng，属训用字。",
        ),
    )

    GuideSubheading("3. 俗字、借音字与新造字")
    GuideParagraph("俗字/借音字：指一般民间或出自文献的用字，有些是借某汉字的台湾台语音读，直接表达一个音同或音近但词义不同的词汇。")
    GuideBulletList(listOf("例：【某】台湾台语读 bóo，可表「妻子」义"))

    GuideParagraph("新造字：当音读与词义都找不到可以使用的汉字时，便需要创造新字。造字原理多为形声，次为会意。")
    GuideBulletList(
        listOf(
            "例：表示「爬、攀登」的【𬦰】peh（形声）",
            "例：表示「长得高」的【躼】lò（会意）",
        ),
    )

    GuideHeading("替代字说明", level = 2)
    GuideParagraph(
        "非本字之用字，本辞典称为「替代字」，故前述「训用字」、「俗字」、「借音字」、「新造字」等都是替代字。" +
                "在用字选择上，我们倾向使用本字，但有以下几种情况，即使本字确定，权衡之下还是有可能会舍弃本字："
    )

    GuideSubheading("1. 本字过于艰深晦涩")
    GuideParagraph("本字过于艰深晦涩，一般大众极不熟悉者。")
    GuideBulletList(listOf("例：表示「耕作之地」的 tshân 本字为【塍】，但我们选择用【田】字来表示。"))

    GuideSubheading("2. 字义与标准语相同且为基本字")
    GuideParagraph("该字字义与对应的标准语用字完全相同，且为极常用的基本字，用本字反而容易造成阅读上的困扰者。")
    GuideBulletList(listOf("例：「人」读作 lâng 的本字为【农】或【儂】，但我们选择用【人】字来替代。"))

    GuideSubheading("3. 约定俗成的俗字")
    GuideParagraph("几乎已经约定俗成、使用也很广泛的俗字，不易改变使用习惯者。")
    GuideBulletList(listOf("例：表示「宰杀」的 thâi 本字是【治】，我们选择使用俗字【刣】来表示。"))

    GuideParagraph(
        "在选字上我们希望能够「望字生音义」，让读者通过该字的形或音而联想到书写者想要表达的概念。" +
                "如表示「低洼泥泞」的 làm 有「坔」和「湳」两种书写形式，其中「坔」是会意字，而「湳」是形声字，" +
                "如果是这两个字来做比较，我们会选择用「湳」，因为形声字的表音功能和意义的联系比较紧密。"
    )

    GuideHeading("推荐用字", level = 2)
    GuideParagraph(
        "教育部分别于民国 96 年及 97 年公告「台湾台语推荐用字」共计 700 字词，本辞典原则上遵照推荐用字之成果。"
    )
}

@Composable
private fun HanjiGuideEnglish() {
    GuideHeading("Hanzi Character Usage Principles")
    GuideParagraph(
        "This page compiles the core principles of Taiwan Hokkien character writing from the Ministry of Education's \"Taiwan Hokkien Dictionary\" for in-app reading."
    )

    GuideHeading("Hanzi Situation", level = 2)
    GuideParagraph(
        "Taiwanese Hokkien differs from Standard Chinese in pronunciation, vocabulary, and syntax. " +
                "Because the separation occurred early in linguistic history, the differences are quite pronounced, leading to more disputes and issues in writing. " +
                "Over the past hundred years, various dictionaries have made different character choices, but there is general agreement on identifying \"original characters.\" " +
                "Scholars continue to accumulate reliable evidence for original characters. However, many characters and words of unknown origin, not derived from Chinese at all, remain, " +
                "creating a \"sounds without characters\" problem."
    )

    GuideHeading("Character Types Used in This Dictionary", level = 2)
    GuideParagraph(
        "Among various writing systems, this dictionary uses hanzi as its foundation, following the principle of \"one sound, one hanzi character.\" " +
                "The standard for character selection depends on how the character is used in practice, combined with the dictionary's established conceptual framework. " +
                "There are generally three types:"
    )

    GuideSubheading("1. Original Characters")
    GuideParagraph(
        "As opposed to \"trained use characters,\" \"phonetic loan characters,\" and \"newly created characters.\" " +
                "These refer to characters with established forms in traditional texts, where the meaning has a shared etymology with Taiwanese Hokkien vocabulary."
    )
    GuideBulletList(
        listOf(
            "Example: The original character for phang (fragrant) is【芳】",
            "Example: The original character for sè (small) is【細】",
        ),
    )

    GuideSubheading("2. Trained Use Characters")
    GuideParagraph(
        "Characters with the same meaning are used to represent the corresponding Taiwanese Hokkien pronunciation of that meaning. " +
                "In terms of character selection, we borrow the meaning but not the sound — we take the meaning of the character form used, " +
                "while the original character for that sound is different."
    )
    GuideBulletList(
        listOf(
            "Example: The character【人】is read jîn in Taiwanese Hokkien, but another way to express \"person\" is lâng, " +
                    "whose original character would be【農】or【儂】. However, this dictionary designates【人】as the character to use; " +
                    "when read as lâng, it is considered a trained use character.",
        ),
    )

    GuideSubheading("3. Colloquial Characters, Loan Characters, and Newly Created Characters")
    GuideParagraph("Colloquial/Loan Characters: Characters commonly used among the general public or found in texts. Some use the Taiwanese Hokkien pronunciation " +
            "of a certain character to directly express a word with the same or similar sound but different meaning.")
    GuideBulletList(listOf("Example: The character【某】read as bóo in Taiwanese Hokkien can mean \"wife\""))

    GuideParagraph("Newly Created Characters: When no existing character can express both the sound and meaning, new characters must be created. " +
            "Most follow the phonetic compound principle, with some following the pictographic/ideographic principle.")
    GuideBulletList(
        listOf(
            "Example: The character【𬦰】meaning \"climb\" is read peh (phonetic compound)",
            "Example: The character【躼】meaning \"tall\" is read lò (pictographic compound)",
        ),
    )

    GuideHeading("Explanations of Alternative Characters", level = 2)
    GuideParagraph(
        "Non-original characters used in this dictionary are called \"alternative characters,\" so the aforementioned trained use characters, " +
                "colloquial characters, loan characters, and newly created characters are all alternative characters. " +
                "In character selection, we prefer original characters, but under the following circumstances, we may choose alternative characters " +
                "even when the original character is confirmed:"
    )

    GuideSubheading("1. Original Characters Too Obscure or Esoteric")
    GuideParagraph("Original characters that are too obscure or esoteric, with which the general public is unfamiliar.")
    GuideBulletList(listOf("Example: The original character for tshân (arable land) is【塍】, but we choose to use【田】instead."))

    GuideSubheading("2. Identical Meaning to Standard Chinese Basic Characters")
    GuideParagraph("Characters with identical meaning to their Standard Chinese equivalents and are extremely common basic characters, " +
            "where using the original character would cause reading difficulty.")
    GuideBulletList(listOf("Example: The original character for lâng (person) is【農】or【儂】, but we choose to use【人】instead."))

    GuideSubheading("3. Established Colloquial Conventions")
    GuideParagraph("Colloquial characters that have become established conventions and are used widely, making it difficult to change usage habits.")
    GuideBulletList(listOf("Example: The original character for thâi (slaughter) is【治】, but we choose to use the colloquial【刣】instead."))

    GuideParagraph(
        "In character selection, we aim for \"reading characters to understand pronunciations and meanings,\" " +
                "allowing readers to associate the character's form or sound with the concept the writer intends to express. " +
                "For instance, làm (muddy/waterlogged) can be written as either「坔」(pictographic) or「湳」(phonetic). " +
                "When comparing these two, we prefer「湳」because the phonetic compound character has a stronger connection between its sound function and meaning."
    )

    GuideHeading("Recommended Characters", level = 2)
    GuideParagraph(
        "The Ministry of Education announced \"Recommended Characters for Taiwan Hokkien\" totaling 700 characters and words in 2007 and 2008. " +
                "This dictionary generally adheres to these recommended characters as a principle."
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
