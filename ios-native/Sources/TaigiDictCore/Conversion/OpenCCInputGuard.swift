import Foundation

public enum OpenCCInputGuard {
    public static func shouldConvert(_ text: String) -> Bool {
        !text.isEmpty && hasValidUTF16Surrogates(text) && containsHanCharacter(text)
    }

    private static func containsHanCharacter(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            switch scalar.value {
            case 0x3400...0x4DBF,
                 0x4E00...0x9FFF,
                 0xF900...0xFAFF,
                 0x20000...0x2A6DF,
                 0x2A700...0x2B73F,
                 0x2B740...0x2B81F,
                 0x2B820...0x2CEAF,
                 0x2CEB0...0x2EBEF,
                 0x30000...0x3134F:
                return true
            default:
                return false
            }
        }
    }

    private static func hasValidUTF16Surrogates(_ text: String) -> Bool {
        var pendingHighSurrogate = false

        for unit in text.utf16 {
            switch unit {
            case 0xD800...0xDBFF:
                if pendingHighSurrogate {
                    return false
                }
                pendingHighSurrogate = true
            case 0xDC00...0xDFFF:
                if !pendingHighSurrogate {
                    return false
                }
                pendingHighSurrogate = false
            default:
                if pendingHighSurrogate {
                    return false
                }
            }
        }

        return !pendingHighSurrogate
    }
}
