import Foundation

public enum AppThemePreference: String, Codable, CaseIterable, Hashable, Sendable {
    case system
    case light
    case dark
    case amoled
}
