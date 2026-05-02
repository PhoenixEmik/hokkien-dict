#!/usr/bin/swift

import Foundation

struct ParsedLocalizations {
    let keys: [String]
    let zhHant: [String: String]
    let zhHans: [String: String]
    let en: [String: String]
}

struct CheckResult {
    let success: Bool
    let messages: [String]
}

enum ExportError: Error, CustomStringConvertible {
    case readFailed(String)
    case writeFailed(String)
    case invalidSource(String)

    var description: String {
        switch self {
        case .readFailed(let message):
            return message
        case .writeFailed(let message):
            return message
        case .invalidSource(let message):
            return message
        }
    }
}

func main() throws {
    let fileManager = FileManager.default
    let currentDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
    let sourcePath = currentDirectory
        .appendingPathComponent("Sources", isDirectory: true)
        .appendingPathComponent("TaigiDictUI", isDirectory: true)
        .appendingPathComponent("AppLocalizer.swift")
    let outputDirectory = currentDirectory
        .appendingPathComponent("Sources", isDirectory: true)
        .appendingPathComponent("TaigiDictUI", isDirectory: true)
        .appendingPathComponent("Resources", isDirectory: true)
    let outputPath = outputDirectory.appendingPathComponent("Localizable.xcstrings")

    guard let source = try? String(contentsOf: sourcePath, encoding: .utf8) else {
        throw ExportError.readFailed("Failed to read source file at \(sourcePath.path)")
    }

    let parsed = try parseLocalizations(from: source)
    let arguments = Set(CommandLine.arguments.dropFirst())
    let checkOnly = arguments.contains("--check")

    if checkOnly {
        let result = try checkCatalogConsistency(parsed: parsed, catalogPath: outputPath)
        for message in result.messages {
            print(message)
        }
        if !result.success {
            exit(2)
        }
        return
    }

    var stringsNode: [String: Any] = [:]
    for key in parsed.keys {
        let zhHantValue = parsed.zhHant[key] ?? ""
        let zhHansValue = parsed.zhHans[key] ?? ""
        let enValue = parsed.en[key] ?? ""

        stringsNode[key] = [
            "localizations": [
                "en": [
                    "stringUnit": [
                        "state": "translated",
                        "value": enValue,
                    ],
                ],
                "zh-Hans": [
                    "stringUnit": [
                        "state": "translated",
                        "value": zhHansValue,
                    ],
                ],
                "zh-Hant": [
                    "stringUnit": [
                        "state": "translated",
                        "value": zhHantValue,
                    ],
                ],
            ],
        ]
    }

    let catalog: [String: Any] = [
        "sourceLanguage": "en",
        "strings": stringsNode,
        "version": "1.0",
    ]

    let encoderOutput = try JSONSerialization.data(withJSONObject: catalog, options: [.prettyPrinted, .sortedKeys])
    guard let outputString = String(data: encoderOutput, encoding: .utf8) else {
        throw ExportError.writeFailed("Failed to encode output JSON")
    }

    if !fileManager.fileExists(atPath: outputDirectory.path) {
        try fileManager.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
    }

    do {
        try outputString.appending("\n").write(to: outputPath, atomically: true, encoding: .utf8)
    } catch {
        throw ExportError.writeFailed("Failed to write xcstrings file at \(outputPath.path): \(error)")
    }

    let missingInAnyLocale = parsed.keys.filter {
        parsed.zhHant[$0] == nil || parsed.zhHans[$0] == nil || parsed.en[$0] == nil
    }

    print("Exported \(parsed.keys.count) keys to \(outputPath.path)")
    if !missingInAnyLocale.isEmpty {
        print("Warning: \(missingInAnyLocale.count) keys were missing in one or more locale tables.")
    }
}

func checkCatalogConsistency(parsed: ParsedLocalizations, catalogPath: URL) throws -> CheckResult {
    guard let data = try? Data(contentsOf: catalogPath) else {
        throw ExportError.readFailed("Failed to read xcstrings file at \(catalogPath.path)")
    }

    guard
        let rootObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
        let stringsObject = rootObject["strings"] as? [String: Any]
    else {
        throw ExportError.invalidSource("Invalid xcstrings structure: missing root strings node")
    }

    let keySet = Set(parsed.keys)
    let catalogKeySet = Set(stringsObject.keys)

    let missingInCatalog = keySet.subtracting(catalogKeySet).sorted()
    let extraInCatalog = catalogKeySet.subtracting(keySet).sorted()

    var messages: [String] = []
    var hasError = false

    if missingInCatalog.isEmpty {
        messages.append("Check: no missing keys in catalog.")
    } else {
        hasError = true
        messages.append("Check failed: missing \(missingInCatalog.count) keys in catalog.")
        messages.append(contentsOf: missingInCatalog.map { "  - \($0)" })
    }

    if extraInCatalog.isEmpty {
        messages.append("Check: no extra keys in catalog.")
    } else {
        hasError = true
        messages.append("Check failed: found \(extraInCatalog.count) extra keys in catalog.")
        messages.append(contentsOf: extraInCatalog.map { "  - \($0)" })
    }

    let requiredLocales = ["en", "zh-Hant", "zh-Hans"]
    for key in parsed.keys {
        guard let row = stringsObject[key] as? [String: Any],
              let localizations = row["localizations"] as? [String: Any]
        else {
            continue
        }

        for locale in requiredLocales {
            guard
                let localeNode = localizations[locale] as? [String: Any],
                let stringUnit = localeNode["stringUnit"] as? [String: Any],
                let value = stringUnit["value"] as? String,
                !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else {
                hasError = true
                messages.append("Check failed: key \(key) missing non-empty value for locale \(locale).")
                continue
            }
        }
    }

    if !hasError {
        messages.append("Check passed: \(parsed.keys.count) keys with complete locale values.")
    }

    return CheckResult(success: !hasError, messages: messages)
}

func parseLocalizations(from source: String) throws -> ParsedLocalizations {
    let lines = source.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

    var keys: [String] = []
    var inKeyEnum = false

    for line in lines {
        if line.contains("public enum AppLocalizedStringKey") {
            inKeyEnum = true
            continue
        }
        if inKeyEnum, line.trimmingCharacters(in: .whitespacesAndNewlines) == "}" {
            inKeyEnum = false
            continue
        }
        if inKeyEnum {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.hasPrefix("case ") else { continue }
            let payload = trimmed.replacingOccurrences(of: "case ", with: "")
            let caseNames = payload.split(separator: ",").map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }.filter { !$0.isEmpty }
            keys.append(contentsOf: caseNames)
        }
    }

    if keys.isEmpty {
        throw ExportError.invalidSource("No AppLocalizedStringKey cases found.")
    }

    let zhHant = extractLocaleMap(lines: lines, functionName: "traditionalChinese")
    let zhHans = extractLocaleMap(lines: lines, functionName: "simplifiedChinese")
    let en = extractLocaleMap(lines: lines, functionName: "english")

    return ParsedLocalizations(keys: keys, zhHant: zhHant, zhHans: zhHans, en: en)
}

func extractLocaleMap(lines: [String], functionName: String) -> [String: String] {
    var map: [String: String] = [:]
    var inFunction = false

    for line in lines {
        if !inFunction, line.contains("private static func \(functionName)") {
            inFunction = true
            continue
        }

        if inFunction {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed == "}" {
                break
            }

            guard trimmed.hasPrefix("case ."), trimmed.contains(": return ") else {
                continue
            }

            let parts = trimmed.components(separatedBy: ": return ")
            guard parts.count == 2 else { continue }

            let keyPart = parts[0].replacingOccurrences(of: "case .", with: "")
            let valuePart = parts[1]

            if let stringValue = parseSwiftStringLiteral(valuePart) {
                map[keyPart] = stringValue
            }
        }
    }

    return map
}

func parseSwiftStringLiteral(_ source: String) -> String? {
    let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.hasPrefix("\"") else { return nil }

    var result = ""
    var escaped = false
    var isInside = false

    for character in trimmed {
        if !isInside {
            if character == "\"" {
                isInside = true
            }
            continue
        }

        if escaped {
            switch character {
            case "n": result.append("\n")
            case "t": result.append("\t")
            case "r": result.append("\r")
            case "\\": result.append("\\")
            case "\"": result.append("\"")
            default: result.append(character)
            }
            escaped = false
            continue
        }

        if character == "\\" {
            escaped = true
            continue
        }

        if character == "\"" {
            return result
        }

        result.append(character)
    }

    return nil
}

do {
    try main()
} catch {
    fputs("error: \(error)\n", stderr)
    exit(1)
}
