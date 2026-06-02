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

            SettingsWindowCommands(
                title: appLanguageManager.localized(.settingsTitle)
            )

            CommandMenu(appLanguageManager.localized(.menuGo)) {
                Button {
                    navigationModel.showDictionary()
                } label: {
                    Label(appLanguageManager.localized(.tabDictionary), systemImage: "book")
                }
                .keyboardShortcut("1", modifiers: [.command])

                Button {
                    navigationModel.showBookmarks()
                } label: {
                    Label(appLanguageManager.localized(.tabBookmarks), systemImage: "bookmark")
                }
                .keyboardShortcut("2", modifiers: [.command])
            }

            ReferenceArticleCommands(
                title: appLanguageManager.localized(.helpViewerTitle)
            )
#endif
        }

#if os(macOS)
        Window(appLanguageManager.localized(.settingsTitle), id: SettingsWindow.windowID) {
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
        .defaultSize(width: 860, height: 620)

        Window("", id: AboutWindow.aboutWindowID) {
            MacAboutWindowView()
                .environmentObject(appLanguageManager)
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)

        Window(appLanguageManager.localized(.settingsLicenses), id: LicenseWindow.licenseWindowID) {
            LicenseSummaryScreen()
                .environmentObject(appLanguageManager)
        }
        .defaultSize(width: 940, height: 560)

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

private enum SettingsWindow {
    static let windowID = "settings-window"
}

private struct AboutWindowCommands: Commands {
    @Environment(\.openWindow) private var openWindow
    let title: String

    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button {
                openWindow(id: AboutWindow.aboutWindowID)
            } label: {
                Label(title, systemImage: "info.circle")
            }
        }
    }
}

private struct SettingsWindowCommands: Commands {
    @Environment(\.openWindow) private var openWindow
    let title: String

    var body: some Commands {
        CommandGroup(replacing: .appSettings) {
            Button {
                openWindow(id: SettingsWindow.windowID)
            } label: {
                Label(title, systemImage: "gearshape")
            }
            .keyboardShortcut(",", modifiers: [.command])
        }
    }
}

private struct ReferenceArticleCommands: Commands {
    @Environment(\.openWindow) private var openWindow
    let title: String

    var body: some Commands {
        CommandGroup(replacing: .help) {
            Button {
                openWindow(id: ReferenceArticleViewerWindow.windowID)
            } label: {
                Label(title, systemImage: "text.book.closed")
            }
        }
    }
}
#endif
