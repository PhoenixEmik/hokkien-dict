package org.taigidict.app.feature.info

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class SimpleMarkdownParserTest {
    @Test
    fun parse_extractsHeadingParagraphAndList() {
        val markdown = """
            # Title

            Intro paragraph line.

            - Item A
            - Item B
        """.trimIndent()

        val blocks = SimpleMarkdownParser.parse(markdown)

        assertEquals(3, blocks.size)
        assertEquals(MarkdownBlock.Heading(level = 1, text = "Title"), blocks[0])
        assertEquals(MarkdownBlock.Paragraph("Intro paragraph line."), blocks[1])
        assertEquals(
            MarkdownBlock.ListBlock(
                ordered = false,
                items = listOf("Item A", "Item B"),
            ),
            blocks[2],
        )
    }

    @Test
    fun parse_extractsMarkdownTable() {
        val markdown = """
            | Name | Value |
            | ---- | ----- |
            | A | 1 |
            | B | 2 |
        """.trimIndent()

        val blocks = SimpleMarkdownParser.parse(markdown)

        assertEquals(1, blocks.size)
        val table = blocks[0] as MarkdownBlock.Table
        assertEquals(listOf("Name", "Value"), table.headers)
        assertEquals(listOf("A", "1"), table.rows[0])
        assertEquals(listOf("B", "2"), table.rows[1])
    }

    @Test
    fun parse_extractsOrderedList() {
        val markdown = """
            1. First
            2. Second
        """.trimIndent()

        val blocks = SimpleMarkdownParser.parse(markdown)

        assertEquals(1, blocks.size)
        val list = blocks[0] as MarkdownBlock.ListBlock
        assertTrue(list.ordered)
        assertEquals(listOf("First", "Second"), list.items)
    }
}