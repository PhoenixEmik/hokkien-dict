import SwiftUI
import TaigiDictCore

public struct TaigiDictAppRootView: View {
    @Environment(\.locale) private var locale
    @StateObject private var appLanguageManager: AppLanguageManager
    @State private var viewModel: DictionarySearchViewModel
    @State private var initializationViewModel = InitializationViewModel()
    @State private var bookmarkStore = BookmarkStore()
    @State private var offlineAudioStore: OfflineAudioStore
    @State private var appSettings = AppSettingsSnapshot()
    @State private var hasLoadedAppSettings = false
    @State private var selectedTab: AppTab = .dictionary

    private let settingsStore: any AppSettingsStoring
    private let conversionService: (any ChineseConversionProviding)?
    private let dictionarySourceStore: (any DictionarySourceResourceManaging)?

    @MainActor
    public init(
        repository: any DictionaryRepositoryProtocol,
        settingsStore: any AppSettingsStoring = UserDefaultsAppSettingsStore(),
        dictionarySourceStore: (any DictionarySourceResourceManaging)? = nil,
        appLanguageManager: AppLanguageManager? = nil
    ) {
        let conversionService = Self.makeChineseConversionService()
        self.conversionService = conversionService
        self.dictionarySourceStore = dictionarySourceStore
        _appLanguageManager = StateObject(wrappedValue: appLanguageManager ?? AppLanguageManager())
        _viewModel = State(initialValue: DictionarySearchViewModel(
            repository: repository,
            conversionService: conversionService
        ))
        _offlineAudioStore = State(initialValue: Self.makeOfflineAudioStore())
        self.settingsStore = settingsStore
    }

    public var body: some View {
        rootContent
        .environmentObject(appLanguageManager)
        .environment(\.locale, appLanguageManager.locale)
        .animation(.easeInOut(duration: 0.2), value: initializationViewModel.isReady)
        .task(id: initializationViewModel.taskID) {
            await Task.yield()
            await initializationViewModel.prepare(using: viewModel)
        }
        .task {
            await AppRootOfflineAudioBootstrap.preload(using: offlineAudioStore)
        }
        .task {
            appLanguageManager.updateSystemLocale(locale)
            await loadAppSettingsIfNeeded()
            syncAppLocaleWithSystem()
        }
        .onChange(of: locale.identifier) { _, _ in
            appLanguageManager.updateSystemLocale(locale)
        }
        .onChange(of: appLocale) { _, _ in
            syncAppLocaleWithSystem()
        }
        .preferredColorScheme(appSettings.themePreference.preferredColorScheme)
        .dynamicTypeSize(appSettings.readingTextScale.dynamicTypeSize)
    }

    @ViewBuilder
    private var rootContent: some View {
        switch AppRootContentPresentation.resolve(isInitializationReady: initializationViewModel.isReady) {
        case .mainTabs:
            mainTabView
        case .initialization:
            InitializationScreen(
                phase: initializationViewModel.phase,
                progress: initializationViewModel.progress,
                errorMessage: initializationViewModel.errorMessage,
                failureReason: initializationViewModel.failureReason
            ) {
                initializationViewModel.retry()
            }
            .transition(.opacity)
        }
    }

    private var mainTabView: some View {
        let currentLocale = appLocale
        return TabView(selection: $selectedTab) {
            DictionarySearchScreen(
                viewModel: viewModel,
                bookmarkStore: bookmarkStore,
                offlineAudioStore: offlineAudioStore,
                conversionService: conversionService
            )
                .tabItem {
                    Label(appLanguageManager.localized(.tabDictionary), systemImage: "book")
                }
                .tag(AppTab.dictionary)

            BookmarksScreen(
                library: viewModel.library,
                bookmarkStore: bookmarkStore,
                offlineAudioStore: offlineAudioStore,
                conversionService: conversionService
            )
            .tabItem {
                Label(appLanguageManager.localized(.tabBookmarks), systemImage: "bookmark")
            }
            .tag(AppTab.bookmarks)

            SettingsScreen(
                library: viewModel.library,
                settingsStore: settingsStore,
                dictionarySourceStore: dictionarySourceStore,
                offlineAudioStore: offlineAudioStore,
                initialSettings: appSettings
            ) {
                Task { @MainActor in
                    await viewModel.resetAfterMaintenance()
                    initializationViewModel.retry()
                }
            } onSettingsChanged: { settings in
                appSettings = settings
            }
            .tabItem {
                Label(appLanguageManager.localized(.tabSettings), systemImage: "gearshape")
            }
            .tag(AppTab.settings)
        }
        .id(currentLocale)
    }

    private var appLocale: AppLocale {
        appLanguageManager.appLocale
    }

    private func loadAppSettingsIfNeeded() async {
        guard !hasLoadedAppSettings else {
            return
        }

        hasLoadedAppSettings = true
        appSettings = await settingsStore.load()
    }

    private func syncAppLocaleWithSystem() {
        viewModel.setAppLocale(appLocale)
    }

    private static func makeChineseConversionService() -> (any ChineseConversionProviding)? {
        LazyChineseConversionService()
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

private enum AppTab: Hashable {
    case dictionary
    case bookmarks
    case settings
}

enum AppRootContentPresentation: Equatable {
    case initialization
    case mainTabs

    static func resolve(isInitializationReady: Bool) -> AppRootContentPresentation {
        isInitializationReady ? .mainTabs : .initialization
    }
}

enum AppRootOfflineAudioBootstrap {
    static func preload(using offlineAudioStore: any OfflineAudioManaging) async {
        for archiveType in AudioArchiveType.allCases {
            _ = await offlineAudioStore.snapshot(for: archiveType)
        }
    }
}

private extension AppThemePreference {
    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
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
