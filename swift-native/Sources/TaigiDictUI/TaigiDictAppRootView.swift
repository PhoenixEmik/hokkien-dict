import SwiftUI
import TaigiDictCore

public struct TaigiDictAppRootView: View {
    @State private var viewModel: DictionarySearchViewModel
    @State private var initializationViewModel = InitializationViewModel()
    @State private var bookmarkStore = BookmarkStore()
    @State private var offlineAudioStore: OfflineAudioStore
    @State private var appSettings = AppSettingsSnapshot()
    @State private var hasLoadedAppSettings = false

    private let settingsStore: any AppSettingsStoring
    private let conversionService: (any ChineseConversionProviding)?

    public init(
        repository: any DictionaryRepositoryProtocol,
        settingsStore: any AppSettingsStoring = UserDefaultsAppSettingsStore()
    ) {
        let conversionService = Self.makeChineseConversionService()
        self.conversionService = conversionService
        _viewModel = State(initialValue: DictionarySearchViewModel(
            repository: repository,
            conversionService: conversionService
        ))
        _offlineAudioStore = State(initialValue: Self.makeOfflineAudioStore())
        self.settingsStore = settingsStore
    }

    public var body: some View {
        Group {
            switch initializationViewModel.state {
            case .ready:
                mainTabView
            case .idle, .loading, .failed:
                InitializationScreen(state: initializationViewModel.state) {
                    initializationViewModel.retry()
                }
            }
        }
        .task(id: initializationViewModel.taskID) {
            await initializationViewModel.prepare(using: viewModel)
        }
        .task {
            await loadAppSettingsIfNeeded()
        }
        .environment(\.locale, Locale(identifier: appSettings.interfaceLocale.rawValue))
        .preferredColorScheme(appSettings.themePreference.preferredColorScheme)
        .dynamicTypeSize(appSettings.readingTextScale.dynamicTypeSize)
    }

    private var mainTabView: some View {
        let appLocale = appSettings.interfaceLocale
        return TabView {
            DictionarySearchScreen(
                viewModel: viewModel,
                bookmarkStore: bookmarkStore,
                offlineAudioStore: offlineAudioStore,
                conversionService: conversionService
            )
                .tabItem {
                    Label(AppLocalizer.text(.tabDictionary, locale: appLocale), systemImage: "book")
                }

            BookmarksScreen(
                library: viewModel.library,
                bookmarkStore: bookmarkStore,
                offlineAudioStore: offlineAudioStore,
                conversionService: conversionService
            )
            .tabItem {
                Label(AppLocalizer.text(.tabBookmarks, locale: appLocale), systemImage: "bookmark")
            }

            SettingsScreen(
                library: viewModel.library,
                settingsStore: settingsStore,
                offlineAudioStore: offlineAudioStore
            ) {
                Task { @MainActor in
                    await viewModel.resetAfterMaintenance()
                    initializationViewModel.retry()
                }
            } onSettingsChanged: { settings in
                appSettings = settings
                viewModel.setAppLocale(settings.interfaceLocale)
            }
            .tabItem {
                Label(AppLocalizer.text(.tabSettings, locale: appLocale), systemImage: "gearshape")
            }
        }
    }

    private func loadAppSettingsIfNeeded() async {
        guard !hasLoadedAppSettings else {
            return
        }

        hasLoadedAppSettings = true
        appSettings = await settingsStore.load()
        viewModel.setAppLocale(appSettings.interfaceLocale)
    }

    private static func makeChineseConversionService() -> (any ChineseConversionProviding)? {
        try? ChineseConversionService()
    }

    private static func makeOfflineAudioStore() -> OfflineAudioStore {
        let baseDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory

        let storage = AudioArchiveStorage(
            rootDirectory: baseDirectory
                .appendingPathComponent("TaigiDictNative", isDirectory: true)
                .appendingPathComponent("Audio", isDirectory: true)
        )
        try? storage.ensureDirectories()

        return OfflineAudioStore(storage: storage)
    }
}

private extension AppThemePreference {
    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark, .amoled:
            return .dark
        }
    }
}

private extension Double {
    var dynamicTypeSize: DynamicTypeSize {
        if self <= 0.9 {
            return .small
        }
        if self <= 1.0 {
            return .large
        }
        if self <= 1.1 {
            return .xLarge
        }
        if self <= 1.2 {
            return .xxLarge
        }
        if self <= 1.3 {
            return .xxxLarge
        }
        return .accessibility1
    }
}
