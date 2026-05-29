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

            AboutWindowCommands(
                title: appLanguageManager.localized(.aboutTitle)
            )

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

            ReferenceArticleCommands(
                title: appLanguageManager.localized(.helpViewerTitle)
            )
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
        .defaultSize(width: 560, height: 430)
        .windowResizability(.contentSize)

        Window("", id: AboutWindow.aboutWindowID) {
            MacAboutWindowView()
                .environmentObject(appLanguageManager)
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)

        Window(appLanguageManager.localized(.settingsLicenses), id: LicenseWindow.licenseWindowID) {
            NavigationStack {
                LicenseSummaryScreen()
            }
            .environmentObject(appLanguageManager)
            .frame(minWidth: 640, minHeight: 480)
        }

        Window(appLanguageManager.localized(.referenceTitle), id: ReferenceArticleViewerWindow.windowID) {
            MacReferenceArticleViewer()
                .environmentObject(appLanguageManager)
        }
        .defaultSize(width: 800, height: 600)
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

#if os(macOS)
private enum AboutWindow {
    static let aboutWindowID = "about-window"
}

private enum LicenseWindow {
    static let licenseWindowID = "license-window"
}

private struct AboutWindowCommands: Commands {
    @Environment(\.openWindow) private var openWindow
    let title: String

    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button(title) {
                openWindow(id: AboutWindow.aboutWindowID)
            }
        }
    }
}

private struct ReferenceArticleCommands: Commands {
    @Environment(\.openWindow) private var openWindow
    let title: String

    var body: some Commands {
        CommandGroup(replacing: .help) {
            Button(title) {
                openWindow(id: ReferenceArticleViewerWindow.windowID)
            }
        }
    }
}
#endif
