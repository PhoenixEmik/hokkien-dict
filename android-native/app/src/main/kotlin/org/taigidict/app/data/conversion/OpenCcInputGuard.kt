package org.taigidict.app.data.conversion

object OpenCcInputGuard {
    fun shouldBypass(text: String): Boolean {
        if (text.isBlank()) {
            return true
        }

        if (!text.hasHanCharacters()) {
            return true
        }

        if (text.hasInvalidSurrogatePair()) {
            return true
        }

        return false
    }

    private fun String.hasHanCharacters(): Boolean {
        return any { char ->
            Character.UnicodeScript.of(char.code) == Character.UnicodeScript.HAN
        }
    }

    private fun String.hasInvalidSurrogatePair(): Boolean {
        var index = 0
        while (index < length) {
            val ch = this[index]
            if (Character.isHighSurrogate(ch)) {
                if (index + 1 >= length || !Character.isLowSurrogate(this[index + 1])) {
                    return true
                }
                index += 2
                continue
            }

            if (Character.isLowSurrogate(ch)) {
                return true
            }

            index += 1
        }

        return false
    }
}