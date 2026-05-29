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
    @State private var bookmarkStore: BookmarkStore
    @State private var bookmarksViewModel: BookmarksViewModel
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
        let searchViewModel = DictionarySearchViewModel(
            repository: repository,
            conversionService: conversionService
        )
        let bookmarkStore = BookmarkStore()
        self.conversionService = conversionService
        self.dictionarySourceStore = dictionarySourceStore
        _appLanguageManager = StateObject(wrappedValue: appLanguageManager ?? AppLanguageManager())
        self.navigationModel = navigationModel
        _viewModel = State(initialValue: searchViewModel)
        _bookmarkStore = State(initialValue: bookmarkStore)
        _bookmarksViewModel = State(initialValue: BookmarksViewModel(
            library: searchViewModel.library,
            bookmarkStore: bookmarkStore
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
#if os(macOS)
        .task {
            await bookmarksViewModel.load()
        }
#endif
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
        MacDictionaryWindowContent(
            dictionaryViewModel: viewModel,
            selection: macSectionSelection,
            bookmarksViewModel: bookmarksViewModel,
            bookmarkStore: bookmarkStore,
            offlineAudioStore: offlineAudioStore,
            conversionService: conversionService,
            settingsStore: settingsStore,
            settingsSnapshot: settingsSnapshot,
            onSettingsChanged: onSettingsChanged
        )
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

#if os(macOS)
private struct MacDictionaryWindowContent: View {
    @Bindable var dictionaryViewModel: DictionarySearchViewModel
    @Binding var selection: MacNavigationSection
    @Environment(\.locale) private var locale
    @State private var selectedBookmarkIDs: Set<Int64> = []
    @State private var primarySelectedBookmarkID: Int64?

    let bookmarksViewModel: BookmarksViewModel
    let bookmarkStore: BookmarkStore
    let offlineAudioStore: (any OfflineAudioManaging)?
    let conversionService: (any ChineseConversionProviding)?
    let settingsStore: any AppSettingsStoring
    let settingsSnapshot: AppSettingsSnapshot
    let onSettingsChanged: (AppSettingsSnapshot) -> Void

    private var appLocale: AppLocale {
        AppLocalizer.appLocale(from: locale)
    }

    private var selectedBookmarkEntry: DictionaryEntry? {
        guard let selectedID = resolvedPrimarySelectedEntryID else {
            return nil
        }

        return bookmarksViewModel.entries.first { $0.id == selectedID }
    }

    private var resolvedPrimarySelectedEntryID: Int64? {
        if let primarySelectedBookmarkID,
           selectedBookmarkIDs.contains(primarySelectedBookmarkID) {
            return primarySelectedBookmarkID
        }

        return bookmarksViewModel.entries.first { selectedBookmarkIDs.contains($0.id) }?.id
    }

    private var searchBinding: Binding<String> {
        Binding(
            get: { dictionaryViewModel.searchText },
            set: { newValue in
                if selection != .dictionary {
                    selection = .dictionary
                }
                dictionaryViewModel.searchText = newValue
            }
        )
    }

    private var bookmarksEntryIDsSignature: [Int64] {
        bookmarksViewModel.entries.map(\.id)
    }

    var body: some View {
        NavigationSplitView {
            sidebarContent
                .frame(minWidth: 280, idealWidth: 320)
        } detail: {
            detailContent
        }
        .navigationTitle(windowTitle)
        .navigationSplitViewStyle(.balanced)
        .searchable(
            text: searchBinding,
            placement: .toolbar,
            prompt: AppLocalizer.text(.searchPrompt, locale: appLocale)
        )
        .onChange(of: dictionaryViewModel.searchText) { _, _ in
            dictionaryViewModel.scheduleSearch()
        }
        .onSubmit(of: .search) {
            dictionaryViewModel.submitSearch()
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                textScaleButton(
                    systemImage: "textformat.size.smaller",
                    label: AppLocalizer.text(.settingsReadingTextScaleLabel, locale: appLocale),
                    nextScale: settingsSnapshot.readingTextScale - readingTextScaleStep,
                    disabled: settingsSnapshot.readingTextScale <= AppSettingsSnapshot.minReadingTextScale
                )
                textScaleButton(
                    systemImage: "textformat.size.larger",
                    label: AppLocalizer.text(.settingsReadingTextScaleLabel, locale: appLocale),
                    nextScale: settingsSnapshot.readingTextScale + readingTextScaleStep,
                    disabled: settingsSnapshot.readingTextScale >= AppSettingsSnapshot.maxReadingTextScale
                )
            }
        }
        .task {
            await bookmarksViewModel.load()
            syncBookmarkSelection()
        }
        .onChange(of: selection) { _, newValue in
            guard newValue == .bookmarks else {
                return
            }

            Task {
                await bookmarksViewModel.load()
                syncBookmarkSelection()
            }
        }
        .onChange(of: bookmarksEntryIDsSignature) { _, _ in
            syncBookmarkSelection()
        }
    }

    @ViewBuilder
    private var sidebarContent: some View {
        switch selection {
        case .dictionary:
            DictionarySearchListView(
                viewModel: dictionaryViewModel,
                showsSelection: true,
                startPresentation: .historyOnly
            )
        case .bookmarks:
            MacBookmarksListView(
                viewModel: bookmarksViewModel,
                selectedEntryIDs: $selectedBookmarkIDs,
                locale: appLocale,
                removeBookmarks: removeBookmarks
            )
        }
    }

    private var detailContent: some View {
        VStack(spacing: 0) {
            MacNavigationFilterBar(selection: $selection, locale: appLocale)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            Divider()

            Group {
                switch selection {
                case .dictionary:
                    dictionaryDetailContent
                case .bookmarks:
                    bookmarksDetailContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private var dictionaryDetailContent: some View {
        if let entry = dictionaryViewModel.selectedEntry {
            DictionaryDetailView(
                entry: entry,
                library: dictionaryViewModel.library,
                bookmarkStore: bookmarkStore,
                offlineAudioStore: offlineAudioStore,
                conversionService: conversionService,
                onBookmarkChanged: reloadBookmarks,
                onOpenLinkedWord: openLinkedDictionaryWord
            )
        } else if dictionaryViewModel.normalizedQuery.isEmpty {
            MacDetailEmptyState(
                title: AppLocalizer.text(.searchStartTitle, locale: appLocale),
                systemImage: "text.magnifyingglass",
                description: AppLocalizer.text(.searchStartDetailDescription, locale: appLocale)
            )
        } else if dictionaryViewModel.isSearching {
            ProgressView(AppLocalizer.text(.searching, locale: appLocale))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if dictionaryViewModel.results.isEmpty {
            ContentUnavailableView(
                AppLocalizer.text(.noResultTitle, locale: appLocale),
                systemImage: "magnifyingglass",
                description: Text(AppLocalizer.text(.noResultDescription, locale: appLocale))
            )
        } else {
            MacDetailEmptyState(
                title: AppLocalizer.text(.searchStartTitle, locale: appLocale),
                systemImage: "text.magnifyingglass",
                description: AppLocalizer.text(.searchStartDetailDescription, locale: appLocale)
            )
        }
    }

    @ViewBuilder
    private var bookmarksDetailContent: some View {
        if let selectedBookmarkEntry {
            DictionaryDetailView(
                entry: selectedBookmarkEntry,
                library: dictionaryViewModel.library,
                bookmarkStore: bookmarkStore,
                offlineAudioStore: offlineAudioStore,
                conversionService: conversionService,
                onBookmarkChanged: reloadBookmarks,
                onOpenLinkedWord: openLinkedDictionaryWord
            )
        } else {
            ContentUnavailableView {
                Label(
                    AppLocalizer.text(.bookmarksEmptyTitle, locale: appLocale),
                    systemImage: "bookmark"
                )
            } description: {
                Text(AppLocalizer.text(.bookmarksEmptyDescription, locale: appLocale))
            } actions: {
                Button(AppLocalizer.text(.bookmarksEmptyAction, locale: appLocale)) {
                    selection = .dictionary
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var windowTitle: String {
        switch selection {
        case .dictionary:
            AppLocalizer.text(.dictionaryTitle, locale: appLocale)
        case .bookmarks:
            AppLocalizer.text(.bookmarksTitle, locale: appLocale)
        }
    }

    private var readingTextScaleStep: Double {
        (AppSettingsSnapshot.maxReadingTextScale - AppSettingsSnapshot.minReadingTextScale)
            / Double(AppSettingsSnapshot.readingTextScaleDivisions)
    }

    @ViewBuilder
    private func textScaleButton(
        systemImage: String,
        label: String,
        nextScale: Double,
        disabled: Bool
    ) -> some View {
        Button {
            Task {
                await updateReadingTextScale(nextScale)
            }
        } label: {
            Image(systemName: systemImage)
        }
        .help(label)
        .disabled(disabled)
    }

    private func updateReadingTextScale(_ value: Double) async {
        let snapped = AppSettingsSnapshot.snapReadingTextScale(value)
        await settingsStore.setReadingTextScale(snapped)
        var nextSettings = settingsSnapshot
        nextSettings.readingTextScale = snapped
        await MainActor.run {
            onSettingsChanged(nextSettings)
        }
    }

    private func removeBookmarks(_ entryIDs: Set<Int64>) {
        Task {
            await bookmarksViewModel.removeBookmarks(entryIDs: entryIDs)
            syncBookmarkSelection()
        }
    }

    private func reloadBookmarks() {
        Task {
            await bookmarksViewModel.load()
            syncBookmarkSelection()
        }
    }

    private func openLinkedDictionaryWord(_ word: String) {
        selection = .dictionary
        Task {
            await dictionaryViewModel.openLinkedWord(word)
        }
    }

    private func syncBookmarkSelection() {
        let validIDs = Set(bookmarksEntryIDsSignature)
        selectedBookmarkIDs = selectedBookmarkIDs.intersection(validIDs)

        if let primarySelectedBookmarkID, validIDs.contains(primarySelectedBookmarkID) {
            return
        }

        if let firstSelected = selectedBookmarkIDs.first {
            primarySelectedBookmarkID = firstSelected
            return
        }

        if let firstEntry = bookmarksViewModel.entries.first {
            primarySelectedBookmarkID = firstEntry.id
            selectedBookmarkIDs = [firstEntry.id]
            return
        }

        primarySelectedBookmarkID = nil
    }
}

private struct MacBookmarksListView: View {
    let viewModel: BookmarksViewModel
    @Binding var selectedEntryIDs: Set<Int64>
    let locale: AppLocale
    let removeBookmarks: (Set<Int64>) -> Void

    var body: some View {
        List(selection: $selectedEntryIDs) {
            if viewModel.isLoading {
                Section {
                    HStack {
                        ProgressView()
                        Text(AppLocalizer.text(.bookmarksLoading, locale: locale))
                    }
                }
            } else if let errorMessage = viewModel.errorMessage {
                Section {
                    ContentUnavailableView(
                        AppLocalizer.text(.loadingFailedTitle, locale: locale),
                        systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage)
                    )
                }
            } else {
                Section(AppLocalizer.text(.bookmarksSectionSaved, locale: locale)) {
                    ForEach(viewModel.entries) { entry in
                        DictionaryEntryRowView(entry: entry, layoutStyle: .sidebarCompact)
                            .tag(entry.id)
                            .contextMenu {
                                Button(role: .destructive) {
                                    removeBookmarks(Set([entry.id]))
                                } label: {
                                    Label(AppLocalizer.text(.commonDelete, locale: locale), systemImage: "trash")
                                }

                                ShareLink(item: WordDetailViewModel.shareText(for: entry)) {
                                    Label(AppLocalizer.text(.share, locale: locale), systemImage: "square.and.arrow.up")
                                }
                            }
                    }
                }
            }
        }
    }
}

private struct MacNavigationFilterBar: View {
    @Binding var selection: MacNavigationSection
    let locale: AppLocale

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterButton(
                    title: AppLocalizer.text(.tabDictionary, locale: locale),
                    section: .dictionary
                )
                filterButton(
                    title: AppLocalizer.text(.tabBookmarks, locale: locale),
                    section: .bookmarks
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollClipDisabled()
    }

    @ViewBuilder
    private func filterButton(title: String, section: MacNavigationSection) -> some View {
        Button {
            selection = section
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(selection == section ? .primary : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(selection == section ? Color.accentColor.opacity(0.12) : Color.clear)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct MacDetailEmptyState: View {
    let title: String
    let systemImage: String
    let description: String

    var body: some View {
        ContentUnavailableView(
            title,
            systemImage: systemImage,
            description: Text(description)
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}
#endif

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
