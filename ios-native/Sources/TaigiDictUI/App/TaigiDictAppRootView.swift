import SwiftUI
import TaigiDictCore
#if os(macOS)
import AppKit
#endif

public struct TaigiDictAppRootView: View {
    @Environment(\.locale) private var locale
    @StateObject private var appLanguageManager: AppLanguageManager
    @ObservedObject private var navigationModel: AppNavigationModel
    @State private var viewModel: DictionarySearchViewModel
    @State private var initializationViewModel = InitializationViewModel()
    @State private var bookmarkStore = BookmarkStore()
    @State private var offlineAudioStore: OfflineAudioStore
    @State private var hasLoadedAppSettings = false
    @State private var selectedIOSTab: IOSAppTab = .dictionary

    private let settingsStore: any AppSettingsStoring
    private let conversionService: (any ChineseConversionProviding)?
    private let dictionarySourceStore: (any DictionarySourceResourceManaging)?
    private let settingsSnapshot: AppSettingsSnapshot
    private let onSettingsChanged: (AppSettingsSnapshot) -> Void
    private let onMaintenanceCompleted: () -> Void
    private let maintenanceToken: UUID

    @MainActor
    public init(
        repository: any DictionaryRepositoryProtocol,
        settingsStore: any AppSettingsStoring = UserDefaultsAppSettingsStore(),
        dictionarySourceStore: (any DictionarySourceResourceManaging)? = nil,
        appLanguageManager: AppLanguageManager? = nil,
        navigationModel: AppNavigationModel = AppNavigationModel(),
        settingsSnapshot: AppSettingsSnapshot = AppSettingsSnapshot(),
        maintenanceToken: UUID = UUID(),
        onMaintenanceCompleted: @escaping () -> Void = {},
        onSettingsChanged: @escaping (AppSettingsSnapshot) -> Void = { _ in }
    ) {
        let conversionService = Self.makeChineseConversionService()
        self.conversionService = conversionService
        self.dictionarySourceStore = dictionarySourceStore
        _appLanguageManager = StateObject(wrappedValue: appLanguageManager ?? AppLanguageManager())
        self.navigationModel = navigationModel
        _viewModel = State(initialValue: DictionarySearchViewModel(
            repository: repository,
            conversionService: conversionService
        ))
        _offlineAudioStore = State(initialValue: Self.makeOfflineAudioStore())
        self.settingsStore = settingsStore
        self.settingsSnapshot = settingsSnapshot
        self.maintenanceToken = maintenanceToken
        self.onMaintenanceCompleted = onMaintenanceCompleted
        self.onSettingsChanged = onSettingsChanged
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
        .onChange(of: maintenanceToken) { _, _ in
            Task { @MainActor in
                await viewModel.resetAfterMaintenance()
                initializationViewModel.retry()
            }
        }
        .onChange(of: locale.identifier) { _, _ in
            appLanguageManager.updateSystemLocale(locale)
        }
        .onChange(of: appLocale) { _, _ in
            syncAppLocaleWithSystem()
        }
        .preferredColorScheme(settingsSnapshot.themePreference.preferredColorScheme)
        .dynamicTypeSize(settingsSnapshot.readingTextScale.dynamicTypeSize)
        .taigiMacWindowToolbarBaselineHidden()
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
        return Group {
#if os(macOS)
            macWindowContent
#else
            TabView(selection: $selectedIOSTab) {
                dictionaryTab
                bookmarksTab
                settingsTab
            }
#endif
        }
        .id(currentLocale)
    }

    private var dictionaryTab: some View {
        DictionarySearchScreen(
            viewModel: viewModel,
            bookmarkStore: bookmarkStore,
            offlineAudioStore: offlineAudioStore,
            conversionService: conversionService,
            macNavigationSelection: macNavigationSelectionOrNil
        )
        .tabItem {
            Label(appLanguageManager.localized(.tabDictionary), systemImage: "book")
        }
        .tag(IOSAppTab.dictionary)
    }

    private var bookmarksTab: some View {
        BookmarksScreen(
            library: viewModel.library,
            bookmarkStore: bookmarkStore,
            offlineAudioStore: offlineAudioStore,
            conversionService: conversionService,
            macNavigationSelection: macNavigationSelectionOrNil,
            onOpenDictionarySearch: {
#if os(macOS)
                navigationModel.showDictionary()
#else
                selectedIOSTab = .dictionary
#endif
            }
        )
        .tabItem {
            Label(appLanguageManager.localized(.tabBookmarks), systemImage: "bookmark")
        }
        .tag(IOSAppTab.bookmarks)
    }

    private var settingsTab: some View {
        SettingsScreen(
            library: viewModel.library,
            settingsStore: settingsStore,
            dictionarySourceStore: dictionarySourceStore,
            offlineAudioStore: offlineAudioStore,
            initialSettings: settingsSnapshot
        ) {
            onMaintenanceCompleted()
        } onSettingsChanged: { settings in
            onSettingsChanged(settings)
        }
        .tabItem {
            Label(appLanguageManager.localized(.tabSettings), systemImage: "gearshape")
        }
        .tag(IOSAppTab.settings)
    }

    private var appLocale: AppLocale {
        appLanguageManager.appLocale
    }

    private func loadAppSettingsIfNeeded() async {
        guard !hasLoadedAppSettings else {
            return
        }

        hasLoadedAppSettings = true
        onSettingsChanged(await settingsStore.load())
    }

    private func syncAppLocaleWithSystem() {
        viewModel.setAppLocale(appLocale)
    }

    private static func makeChineseConversionService() -> (any ChineseConversionProviding)? {
        LazyChineseConversionService()
    }

    private static func makeOfflineAudioStore() -> OfflineAudioStore {
        let appStorage = TaigiDictAppStorage.resolve()
        try? appStorage.prepareAudioDirectory()

        let storage = AudioArchiveStorage(rootDirectory: appStorage.audioDirectory)
        try? storage.ensureDirectories()

        return OfflineAudioStore(storage: storage)
    }

#if os(macOS)
    private var macSectionSelection: Binding<MacNavigationSection> {
        Binding(
            get: { navigationModel.selectedSection },
            set: { navigationModel.selectedSection = $0 }
        )
    }

    private var macNavigationSelectionOrNil: Binding<MacNavigationSection>? {
        macSectionSelection
    }

    private var macWindowContent: some View {
        Group {
            switch navigationModel.selectedSection {
            case .dictionary:
                dictionaryTab
            case .bookmarks:
                bookmarksTab
            }
        }
    }
#else
    private var macNavigationSelectionOrNil: Binding<MacNavigationSection>? {
        nil
    }
#endif
}

public final class AppNavigationModel: ObservableObject {
    @Published var selectedSection: MacNavigationSection = .dictionary

    public init() {}

    public func showDictionary() {
        selectedSection = .dictionary
    }

    public func showBookmarks() {
        selectedSection = .bookmarks
    }
}

private extension View {
    @ViewBuilder
    func taigiMacWindowToolbarBaselineHidden() -> some View {
#if os(macOS)
        background(MacWindowToolbarConfigurator())
#else
        self
#endif
    }
}

#if os(macOS)
private struct MacWindowToolbarConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            context.coordinator.applyConfiguration(for: view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.applyConfiguration(for: nsView)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        private weak var configuredWindow: NSWindow?

        func applyConfiguration(for view: NSView) {
            guard let window = view.window else {
                return
            }

            guard configuredWindow !== window || window.toolbar?.showsBaselineSeparator != false else {
                return
            }

            configuredWindow = window
            window.toolbar?.showsBaselineSeparator = false
        }
    }
}
#endif

public enum MacNavigationSection: Hashable {
    case dictionary
    case bookmarks
}

private enum IOSAppTab: Hashable {
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
