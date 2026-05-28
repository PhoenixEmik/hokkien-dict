import SwiftUI
import TaigiDictCore
import TaigiDictUI

@main
struct TaigiDictNativeApp: App {
    private static let appStorage = TaigiDictAppStorage.resolve()
    @StateObject private var appLanguageManager = AppLanguageManager()
    @StateObject private var navigationModel = AppNavigationModel()

    var body: some Scene {
        WindowGroup {
            TaigiDictAppRootView(
                repository: InstalledDictionaryRepository(
                    sourceDirectory: Self.appStorage.dictionarySourceDirectory,
                    installedDirectory: Self.appStorage.installedDictionaryDirectory,
                    fallbackSourceDirectory: Self.bundledDictionaryDirectory
                ),
                dictionarySourceStore: DictionarySourceResourceStore(
                    bundledDirectory: Self.bundledDictionaryDirectory,
                    localDirectory: Self.appStorage.dictionarySourceDirectory
                ),
                appLanguageManager: appLanguageManager,
                navigationModel: navigationModel
            )
        }
        .commands {
#if os(macOS)
            CommandGroup(after: .sidebar) {
                Button(appLanguageManager.localized(.tabDictionary)) {
                    navigationModel.showDictionary()
                }
                .keyboardShortcut("1", modifiers: [.command])

                Button(appLanguageManager.localized(.tabBookmarks)) {
                    navigationModel.showBookmarks()
                }
                .keyboardShortcut("2", modifiers: [.command])

                Button(appLanguageManager.localized(.tabSettings)) {
                    navigationModel.showSettings()
                }
                .keyboardShortcut("3", modifiers: [.command])
            }
#endif
        }
    }

    private static var bundledDictionaryDirectory: URL {
        guard let url = Bundle.main.url(forResource: "Dictionary", withExtension: nil) else {
            preconditionFailure("Bundled dictionary package is missing.")
        }
        return url
    }
}
