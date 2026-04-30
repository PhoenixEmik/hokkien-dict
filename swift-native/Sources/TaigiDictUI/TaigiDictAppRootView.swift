import SwiftUI
import TaigiDictCore

public struct TaigiDictAppRootView: View {
    @State private var viewModel: DictionarySearchViewModel
    @State private var initializationViewModel = InitializationViewModel()
    @State private var bookmarkStore = BookmarkStore()
    @State private var appSettings = AppSettingsSnapshot()
    @State private var hasLoadedAppSettings = false

    private let settingsStore: any AppSettingsStoring

    public init(
        repository: any DictionaryRepositoryProtocol,
        settingsStore: any AppSettingsStoring = UserDefaultsAppSettingsStore()
    ) {
        _viewModel = State(initialValue: DictionarySearchViewModel(repository: repository))
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
        TabView {
            DictionarySearchScreen(viewModel: viewModel, bookmarkStore: bookmarkStore)
                .tabItem {
                    Label("辭典", systemImage: "book")
                }

            BookmarksScreen(library: viewModel.library, bookmarkStore: bookmarkStore)
            .tabItem {
                Label("書籤", systemImage: "bookmark")
            }

            SettingsScreen(
                library: viewModel.library,
                settingsStore: settingsStore
            ) {
                Task { @MainActor in
                    await viewModel.resetAfterMaintenance()
                    initializationViewModel.retry()
                }
            } onSettingsChanged: { settings in
                appSettings = settings
            }
            .tabItem {
                Label("設定", systemImage: "gearshape")
            }
        }
    }

    private func loadAppSettingsIfNeeded() async {
        guard !hasLoadedAppSettings else {
            return
        }

        hasLoadedAppSettings = true
        appSettings = await settingsStore.load()
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
