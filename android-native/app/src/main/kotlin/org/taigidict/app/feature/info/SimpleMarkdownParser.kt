package org.taigidict.app.feature.info

internal sealed interface MarkdownBlock {
    data class Heading(val level: Int, val text: String) : MarkdownBlock

    data class Paragraph(val text: String) : MarkdownBlock

    data class ListBlock(
        val ordered: Boolean,
        val items: List<String>,
    ) : MarkdownBlock

    data class Table(
        val headers: List<String>,
        val rows: List<List<String>>,
    ) : MarkdownBlock
}

internal object SimpleMarkdownParser {
    private val headingRegex = Regex("^(#{1,6})\\s+(.+)$")
    private val unorderedItemRegex = Regex("^[-*]\\s+(.+)$")
    private val orderedItemRegex = Regex("^\\d+[.)]\\s+(.+)$")
    private val tableSeparatorRegex = Regex("^\\s*\\|?(\\s*:?-{3,}:?\\s*\\|)+\\s*:?-{3,}:?\\s*\\|?\\s*$")

    fun parse(markdown: String): List<MarkdownBlock> {
        val lines = markdown.lines()
        val blocks = mutableListOf<MarkdownBlock>()
        val paragraphBuffer = mutableListOf<String>()
        var index = 0

        fun flushParagraph() {
            if (paragraphBuffer.isEmpty()) return
            val text = paragraphBuffer.joinToString(" ") { it.trim() }.trim()
            if (text.isNotEmpty()) {
                blocks += MarkdownBlock.Paragraph(text)
            }
            paragraphBuffer.clear()
        }

        while (index < lines.size) {
            val line = lines[index]
            val trimmed = line.trim()

            if (trimmed.isEmpty()) {
                flushParagraph()
                index += 1
                continue
            }

            headingRegex.matchEntire(trimmed)?.let { match ->
                flushParagraph()
                blocks += MarkdownBlock.Heading(
                    level = match.groupValues[1].length,
                    text = match.groupValues[2].trim(),
                )
                index += 1
                return@let
            }?.also { continue }

            if (isTableStart(lines, index)) {
                flushParagraph()
                val (table, consumedLines) = parseTable(lines, index)
                blocks += table
                index += consumedLines
                continue
            }

            unorderedItemRegex.matchEntire(trimmed)?.let {
                flushParagraph()
                val items = mutableListOf<String>()
                var cursor = index
                while (cursor < lines.size) {
                    val next = lines[cursor].trim()
                    val matched = unorderedItemRegex.matchEntire(next) ?: break
                    items += matched.groupValues[1].trim()
                    cursor += 1
                }
                if (items.isNotEmpty()) {
                    blocks += MarkdownBlock.ListBlock(
                        ordered = false,
                        items = items,
                    )
                }
                index = cursor
                continue
            }

            orderedItemRegex.matchEntire(trimmed)?.let {
                flushParagraph()
                val items = mutableListOf<String>()
                var cursor = index
                while (cursor < lines.size) {
                    val next = lines[cursor].trim()
                    val matched = orderedItemRegex.matchEntire(next) ?: break
                    items += matched.groupValues[1].trim()
                    cursor += 1
                }
                if (items.isNotEmpty()) {
                    blocks += MarkdownBlock.ListBlock(
                        ordered = true,
                        items = items,
                    )
                }
                index = cursor
                continue
            }

            paragraphBuffer += trimmed
            index += 1
        }

        flushParagraph()
        return blocks
    }

    private fun isTableStart(lines: List<String>, index: Int): Boolean {
        if (index + 1 >= lines.size) return false
        val headerLine = lines[index].trim()
        val separatorLine = lines[index + 1].trim()
        return headerLine.contains('|') && tableSeparatorRegex.matches(separatorLine)
    }

    private fun parseTable(
        lines: List<String>,
        index: Int,
    ): Pair<MarkdownBlock.Table, Int> {
        val headers = splitTableCells(lines[index])
        val rows = mutableListOf<List<String>>()
        var consumed = 2 // header + separator
        var cursor = index + 2

        while (cursor < lines.size) {
            val line = lines[cursor]
            if (!line.contains('|') || line.trim().isEmpty()) {
                break
            }
            rows += splitTableCells(line)
            consumed += 1
            cursor += 1
        }

        return MarkdownBlock.Table(headers = headers, rows = rows) to consumed
    }

    private fun splitTableCells(line: String): List<String> {
        return line
            .trim()
            .trim('|')
            .split('|')
            .map { it.trim() }
    }
}