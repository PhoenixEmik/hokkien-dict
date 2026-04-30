import SwiftUI
import TaigiDictCore

public struct TaigiDictAppRootView: View {
    private static let initializationRevealDelay = Duration.milliseconds(220)

    @State private var viewModel: DictionarySearchViewModel
    @State private var initializationViewModel = InitializationViewModel()
    @State private var shouldShowInitializationScreen = false
    @State private var bookmarkStore = BookmarkStore()
    @State private var offlineAudioStore: OfflineAudioStore
    @State private var appSettings = AppSettingsSnapshot()
    @State private var hasLoadedAppSettings = false
    @State private var selectedTab: AppTab = .dictionary

    private let settingsStore: any AppSettingsStoring
    private let conversionService: (any ChineseConversionProviding)?
    private let dictionarySourceStore: (any DictionarySourceResourceManaging)?

    public init(
        repository: any DictionaryRepositoryProtocol,
        settingsStore: any AppSettingsStoring = UserDefaultsAppSettingsStore(),
        dictionarySourceStore: (any DictionarySourceResourceManaging)? = nil
    ) {
        let conversionService = Self.makeChineseConversionService()
        self.conversionService = conversionService
        self.dictionarySourceStore = dictionarySourceStore
        _viewModel = State(initialValue: DictionarySearchViewModel(
            repository: repository,
            conversionService: conversionService
        ))
        _offlineAudioStore = State(initialValue: Self.makeOfflineAudioStore())
        self.settingsStore = settingsStore
    }

    public var body: some View {
        rootContent
        .animation(.easeInOut(duration: 0.2), value: shouldShowInitializationScreen)
        .animation(.easeInOut(duration: 0.2), value: initializationViewModel.isReady)
        .task(id: initializationViewModel.taskID) {
            shouldShowInitializationScreen = false

            let revealTask = Task {
                try? await Task.sleep(for: Self.initializationRevealDelay)
                guard !Task.isCancelled else {
                    return
                }

                await MainActor.run {
                    guard !initializationViewModel.isReady else {
                        return
                    }

                    shouldShowInitializationScreen = true
                }
            }

            await Task.yield()
            await initializationViewModel.prepare(using: viewModel)
            revealTask.cancel()

            if !initializationViewModel.isReady {
                shouldShowInitializationScreen = true
            }
        }
        .task {
            await loadAppSettingsIfNeeded()
        }
        .environment(\.locale, Locale(identifier: appSettings.interfaceLocale.rawValue))
        .preferredColorScheme(appSettings.themePreference.preferredColorScheme)
        .dynamicTypeSize(appSettings.readingTextScale.dynamicTypeSize)
    }

    @ViewBuilder
    private var rootContent: some View {
        if initializationViewModel.isReady {
            mainTabView
        } else if shouldShowInitializationScreen {
            InitializationScreen(
                phase: initializationViewModel.phase,
                progress: initializationViewModel.progress,
                errorMessage: initializationViewModel.errorMessage,
                failureReason: initializationViewModel.failureReason
            ) {
                initializationViewModel.retry()
            }
            .transition(.opacity)
        } else {
            Color.clear
                .ignoresSafeArea()
        }
    }

    private var mainTabView: some View {
        let appLocale = appSettings.interfaceLocale
        return TabView(selection: $selectedTab) {
            DictionarySearchScreen(
                viewModel: viewModel,
                bookmarkStore: bookmarkStore,
                offlineAudioStore: offlineAudioStore,
                conversionService: conversionService
            )
                .tabItem {
                    Label(AppLocalizer.text(.tabDictionary, locale: appLocale), systemImage: "book")
                }
                .tag(AppTab.dictionary)

            BookmarksScreen(
                library: viewModel.library,
                bookmarkStore: bookmarkStore,
                offlineAudioStore: offlineAudioStore,
                conversionService: conversionService
            )
            .tabItem {
                Label(AppLocalizer.text(.tabBookmarks, locale: appLocale), systemImage: "bookmark")
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
                viewModel.setAppLocale(settings.interfaceLocale)
            }
            .tabItem {
                Label(AppLocalizer.text(.tabSettings, locale: appLocale), systemImage: "gearshape")
            }
            .tag(AppTab.settings)
        }
        .id(appSettings.interfaceLocale)
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

private enum AppTab: Hashable {
    case dictionary
    case bookmarks
    case settings
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
