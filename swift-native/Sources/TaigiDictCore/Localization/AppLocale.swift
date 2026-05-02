import Foundation

public enum AppLocale: String, Codable, CaseIterable, Hashable, Sendable {
    case english = "en"
    case simplifiedChinese = "zh-CN"
    case traditionalChinese = "zh-TW"

    public var usesSimplifiedChineseDisplay: Bool {
        self == .simplifiedChinese
    }
}
