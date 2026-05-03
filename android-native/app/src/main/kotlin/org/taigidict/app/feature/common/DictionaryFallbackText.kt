package org.taigidict.app.feature.common

import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import org.taigidict.app.R

internal object DictionaryFallbackTextRanges {
    fun fallbackRanges(text: String): List<IntRange> {
        if (text.isEmpty()) {
            return emptyList()
        }

        val marked = BooleanArray(text.length)
        var index = 0
        while (index < text.length) {
            val codePoint = text.codePointAt(index)
            val charCount = Character.charCount(codePoint)
            val endExclusive = index + charCount

            if (requiresTauhuOo(codePoint)) {
                var cursor = index
                while (cursor < endExclusive) {
                    marked[cursor] = true
                    cursor += 1
                }
                if (isCombiningMark(codePoint) && index > 0) {
                    marked[index - 1] = true
                }
            }

            index = endExclusive
        }

        val ranges = mutableListOf<IntRange>()
        var cursor = 0
        while (cursor < marked.size) {
            if (!marked[cursor]) {
                cursor += 1
                continue
            }
            val start = cursor
            while (cursor + 1 < marked.size && marked[cursor + 1]) {
                cursor += 1
            }
            ranges += start..cursor
            cursor += 1
        }

        return ranges
    }

    private fun requiresTauhuOo(codePoint: Int): Boolean {
        return codePoint == SUPERSCRIPT_N ||
            codePoint == COMBINING_DOT_ABOVE_RIGHT ||
            isCombiningMark(codePoint) ||
            isCjkExtension(codePoint)
    }

    private fun isCombiningMark(codePoint: Int): Boolean {
        return codePoint in COMBINING_DIACRITIC_START..COMBINING_DIACRITIC_END
    }

    private fun isCjkExtension(codePoint: Int): Boolean {
        return codePoint in CJK_EXTENSION_A_START..CJK_EXTENSION_A_END ||
            codePoint in CJK_EXTENSION_B_START..CJK_EXTENSION_B_END ||
            codePoint in CJK_EXTENSION_C_START..CJK_EXTENSION_C_END ||
            codePoint in CJK_EXTENSION_D_START..CJK_EXTENSION_D_END ||
            codePoint in CJK_EXTENSION_E_START..CJK_EXTENSION_E_END ||
            codePoint in CJK_EXTENSION_F_START..CJK_EXTENSION_F_END ||
            codePoint in CJK_EXTENSION_G_START..CJK_EXTENSION_G_END ||
            codePoint in CJK_EXTENSION_H_START..CJK_EXTENSION_H_END
    }

    private const val SUPERSCRIPT_N = 0x207F
    private const val COMBINING_DOT_ABOVE_RIGHT = 0x0358
    private const val COMBINING_DIACRITIC_START = 0x0300
    private const val COMBINING_DIACRITIC_END = 0x036F

    private const val CJK_EXTENSION_A_START = 0x3400
    private const val CJK_EXTENSION_A_END = 0x4DBF
    private const val CJK_EXTENSION_B_START = 0x20000
    private const val CJK_EXTENSION_B_END = 0x2A6DF
    private const val CJK_EXTENSION_C_START = 0x2A700
    private const val CJK_EXTENSION_C_END = 0x2B73F
    private const val CJK_EXTENSION_D_START = 0x2B740
    private const val CJK_EXTENSION_D_END = 0x2B81F
    private const val CJK_EXTENSION_E_START = 0x2B820
    private const val CJK_EXTENSION_E_END = 0x2CEAF
    private const val CJK_EXTENSION_F_START = 0x2CEB0
    private const val CJK_EXTENSION_F_END = 0x2EBEF
    private const val CJK_EXTENSION_G_START = 0x30000
    private const val CJK_EXTENSION_G_END = 0x3134F
    private const val CJK_EXTENSION_H_START = 0x31350
    private const val CJK_EXTENSION_H_END = 0x323AF
}

private val TauhuOoFontFamily = FontFamily(
    Font(R.font.tauhuoo_20_05_regular, FontWeight.Normal),
)

@Composable
fun DictionaryFallbackText(
    text: String,
    modifier: Modifier = Modifier,
    style: TextStyle,
    color: Color = Color.Unspecified,
) {
    val renderedText = remember(text) {
        val ranges = DictionaryFallbackTextRanges.fallbackRanges(text)
        if (ranges.isEmpty()) {
            AnnotatedString(text)
        } else {
            buildAnnotatedString(text, ranges)
        }
    }

    Text(
        text = renderedText,
        modifier = modifier,
        style = style,
        color = color,
    )
}

private fun buildAnnotatedString(
    text: String,
    ranges: List<IntRange>,
): AnnotatedString {
    val builder = AnnotatedString.Builder(text)
    ranges.forEach { range ->
        builder.addStyle(
            style = SpanStyle(fontFamily = TauhuOoFontFamily),
            start = range.first,
            end = range.last + 1,
        )
    }
    return builder.toAnnotatedString()
}
