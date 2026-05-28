import SwiftUI
import TaigiDictCore
import TaigiDictUI

@main
struct TaigiDictNativeApp: App {
    private static let appStorage = TaigiDictAppStorage.resolve()
    private static let repository = InstalledDictionaryRepository(
        sourceDirectory: appStorage.dictionarySourceDirectory,
        installedDirectory: appStorage.installedDictionaryDirectory,
        fallbackSourceDirectory: bundledDictionaryDirectory
    )
    private static let settingsStore = UserDefaultsAppSettingsStore()
    private static let dictionarySourceStore = DictionarySourceResourceStore(
        bundledDirectory: bundledDictionaryDirectory,
        localDirectory: appStorage.dictionarySourceDirectory
    )
    private static let settingsLibrary = DictionaryLibrary(repository: repository)
    private static let settingsOfflineAudioStore = makeOfflineAudioStore()

    @StateObject private var appLanguageManager = AppLanguageManager()
    @StateObject private var navigationModel = AppNavigationModel()
    @State private var settingsSnapshot = AppSettingsSnapshot()
    @State private var maintenanceToken = UUID()

    var body: some Scene {
        WindowGroup {
            TaigiDictAppRootView(
                repository: Self.repository,
                settingsStore: Self.settingsStore,
                dictionarySourceStore: Self.dictionarySourceStore,
                appLanguageManager: appLanguageManager,
                navigationModel: navigationModel,
                settingsSnapshot: settingsSnapshot,
                maintenanceToken: maintenanceToken,
                onMaintenanceCompleted: {
                    maintenanceToken = UUID()
                },
                onSettingsChanged: { settings in
                    settingsSnapshot = settings
                }
            )
        }
        .commands {
#if os(macOS)
            SidebarCommands()

            CommandMenu(appLanguageManager.localized(.menuGo)) {
                Button(appLanguageManager.localized(.tabDictionary)) {
                    navigationModel.showDictionary()
                }
                .keyboardShortcut("1", modifiers: [.command])

                Button(appLanguageManager.localized(.tabBookmarks)) {
                    navigationModel.showBookmarks()
                }
                .keyboardShortcut("2", modifiers: [.command])
            }
#endif
        }

#if os(macOS)
        Settings {
            SettingsScreen(
                library: Self.settingsLibrary,
                settingsStore: Self.settingsStore,
                dictionarySourceStore: Self.dictionarySourceStore,
                offlineAudioStore: Self.settingsOfflineAudioStore,
                initialSettings: settingsSnapshot
            ) {
                maintenanceToken = UUID()
            } onSettingsChanged: { settings in
                settingsSnapshot = settings
            }
            .environmentObject(appLanguageManager)
        }
#endif
    }

    private static func makeOfflineAudioStore() -> OfflineAudioStore {
        try? appStorage.prepareAudioDirectory()
        let storage = AudioArchiveStorage(rootDirectory: appStorage.audioDirectory)
        try? storage.ensureDirectories()
        return OfflineAudioStore(storage: storage)
    }

    private static var bundledDictionaryDirectory: URL {
        guard let url = Bundle.main.url(forResource: "Dictionary", withExtension: nil) else {
            preconditionFailure("Bundled dictionary package is missing.")
        }
        return url
    }
}
