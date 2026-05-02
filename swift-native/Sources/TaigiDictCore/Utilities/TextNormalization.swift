import Foundation

public enum TextNormalization {
    private static let romanizationFold: [Character: String] = [
        "á": "a",
        "à": "a",
        "â": "a",
        "ǎ": "a",
        "ā": "a",
        "ä": "a",
        "ã": "a",
        "é": "e",
        "è": "e",
        "ê": "e",
        "ē": "e",
        "ë": "e",
        "í": "i",
        "ì": "i",
        "î": "i",
        "ī": "i",
        "ï": "i",
        "ó": "o",
        "ò": "o",
        "ô": "o",
        "ō": "o",
        "ö": "o",
        "ő": "o",
        "ú": "u",
        "ù": "u",
        "û": "u",
        "ū": "u",
        "ü": "u",
        "ḿ": "m",
        "ń": "n",
        "ǹ": "n",
    ]

    public static func normalizedSearchText(_ text: String) -> String {
        normalizeQuery(text)
    }

    public static func normalizeQuery(_ input: String) -> String {
        var normalized = removeTones(input.trimmingCharacters(in: .whitespacesAndNewlines))
        normalized = normalized.removingToneNumbers()
        normalized = normalized.collapsingWhitespace()
        normalized = normalized.replacingOccurrences(of: #"[-_/]"#, with: " ", options: .regularExpression)
        normalized = normalized.replacingOccurrences(
            of: #"[【】\[\]（）()、,.;:!?"'`]+"#,
            with: " ",
            options: .regularExpression
        )
        return normalized.collapsingWhitespace()
    }

    public static func removeTones(_ input: String) -> String {
        var output = ""
        output.reserveCapacity(input.count)

        for character in input.lowercased() {
            if let replacement = romanizationFold[character] {
                output.append(replacement)
            } else {
                output.append(character)
            }
        }

        output = output.removingCombiningMarks()
        output = output.replacingOccurrences(of: "o\u{0358}", with: "oo")
        output = output.replacingOccurrences(of: "\u{207F}", with: "n")
        return output.removingToneNumbers()
    }
}

private extension String {
    func removingToneNumbers() -> String {
        replacingOccurrences(of: #"[1-8]"#, with: "", options: .regularExpression)
    }

    func removingCombiningMarks() -> String {
        unicodeScalars.reduce(into: "") { result, scalar in
            if (0x0300...0x036F).contains(Int(scalar.value)) {
                return
            }
            result.unicodeScalars.append(scalar)
        }
    }

    func collapsingWhitespace() -> String {
        replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
