import SwiftUI
import TaigiDictCore
#if os(macOS)
import AppKit
#endif

public struct DictionarySearchScreen: View {
    @Bindable private var viewModel: DictionarySearchViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.locale) private var locale
    private let bookmarkStore: (any BookmarksStoreProtocol)?
    private let offlineAudioStore: (any OfflineAudioManaging)?
    private let conversionService: (any ChineseConversionProviding)?
    private let macNavigationSelection: Binding<MacNavigationSection>?

    public init(
        viewModel: DictionarySearchViewModel,
        bookmarkStore: (any BookmarksStoreProtocol)? = nil,
        offlineAudioStore: (any OfflineAudioManaging)? = nil,
        conversionService: (any ChineseConversionProviding)? = nil,
        macNavigationSelection: Binding<MacNavigationSection>? = nil
    ) {
        _viewModel = Bindable(viewModel)
        self.bookmarkStore = bookmarkStore
        self.offlineAudioStore = offlineAudioStore
        self.conversionService = conversionService
        self.macNavigationSelection = macNavigationSelection
    }

    private var appLocale: AppLocale {
        AppLocalizer.appLocale(from: locale)
    }

    public var body: some View {
        let dictionaryTitle = AppLocalizer.text(.dictionaryTitle, locale: appLocale)
        let searchTitle = AppLocalizer.text(.searchTitle, locale: appLocale)

        switch DictionarySearchPresentation.resolve(
            horizontalSizeClass: horizontalSizeClass,
            isSearching: viewModel.isSearching,
            hasResults: !viewModel.results.isEmpty
        ) {
        case .desktopSinglePane:
            desktopSinglePaneContainer()
        case .desktopResultsSplit:
            NavigationSplitView {
                DictionarySearchListView(
                    viewModel: viewModel,
                    showsSelection: true,
                    startPresentation: .historyOnly
                )
            } detail: {
                DictionaryDetailView(
                    entry: viewModel.selectedEntry,
                    library: viewModel.library,
                    bookmarkStore: bookmarkStore,
                    offlineAudioStore: offlineAudioStore,
                    conversionService: conversionService
                )
            }
            .navigationSplitViewStyle(.balanced)
        case .regularSplit:
            NavigationSplitView {
                DictionarySearchListView(
                    viewModel: viewModel,
                    showsSelection: true,
                    startPresentation: .historyOnly
                )
                .navigationTitle(searchTitle)
            } detail: {
                DictionaryDetailView(
                    entry: viewModel.selectedEntry,
                    library: viewModel.library,
                    bookmarkStore: bookmarkStore,
                    offlineAudioStore: offlineAudioStore,
                    conversionService: conversionService
                )
                .navigationTitle(DictionarySearchNavigationTitle.detailTitle(
                    selectedEntryHanji: viewModel.selectedEntry?.hanji,
                    dictionaryTitle: dictionaryTitle
                ))
            }
            .navigationSplitViewStyle(.balanced)
        case .compactStack:
            NavigationStack {
                DictionarySearchListView(viewModel: viewModel, showsSelection: false)
                    .navigationTitle(dictionaryTitle)
                    .navigationDestination(item: $viewModel.detailEntry) { entry in
                        DictionaryDetailView(
                            entry: entry,
                            library: viewModel.library,
                            bookmarkStore: bookmarkStore,
                            offlineAudioStore: offlineAudioStore,
                            conversionService: conversionService
                        )
                        .navigationTitle(entry.hanji)
                        #if os(iOS)
                        .navigationBarTitleDisplayMode(.inline)
                        #endif
                    }
            }
        }
    }

    private func desktopSinglePaneContainer() -> some View {
        NavigationStack {
            DictionaryDesktopSinglePaneView(viewModel: viewModel)
                .navigationDestination(item: $viewModel.detailEntry) { entry in
                    DictionaryDetailView(
                        entry: entry,
                        library: viewModel.library,
                        bookmarkStore: bookmarkStore,
                        offlineAudioStore: offlineAudioStore,
                        conversionService: conversionService
                    )
                    .navigationTitle(entry.hanji)
                }
        }
    }
}

enum DictionarySearchNavigationTitle {
    static func detailTitle(selectedEntryHanji: String?, dictionaryTitle: String) -> String {
        dictionaryTitle
    }
}

enum DictionarySearchPresentation: Equatable {
    case desktopSinglePane
    case desktopResultsSplit
    case compactStack
    case regularSplit

    static func resolve(
        horizontalSizeClass: UserInterfaceSizeClass?,
        prefersDesktopLayout: Bool = Self.prefersDesktopLayout,
        isSearching: Bool = false,
        hasResults: Bool = false
    ) -> DictionarySearchPresentation {
        if prefersDesktopLayout {
            return .desktopResultsSplit
        }

        if horizontalSizeClass == .regular {
            return .regularSplit
        }

        return .compactStack
    }

    private static var prefersDesktopLayout: Bool {
#if os(macOS)
        true
#else
        false
#endif
    }
}

private struct DictionaryDesktopSinglePaneView: View {
    @Bindable var viewModel: DictionarySearchViewModel
    @Environment(\.locale) private var locale

    private var appLocale: AppLocale {
        AppLocalizer.appLocale(from: locale)
    }

    var body: some View {
        Group {
            if viewModel.isLoading {
                centeredState {
                    ProgressView(AppLocalizer.text(.loadingDictionary, locale: appLocale))
                }
            } else if let errorMessage = viewModel.errorMessage {
                centeredState {
                    ContentUnavailableView(
                        AppLocalizer.text(.loadingFailedTitle, locale: appLocale),
                        systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage)
                    )
                }
            } else if viewModel.normalizedQuery.isEmpty {
                desktopStartState
            } else {
                centeredState {
                    ContentUnavailableView(
                        AppLocalizer.text(.noResultTitle, locale: appLocale),
                        systemImage: "magnifyingglass",
                        description: Text(AppLocalizer.text(.noResultDescription, locale: appLocale))
                    )
                }
            }
        }
        .animation(.easeOut(duration: 0.12), value: viewModel.isSearching)
        .animation(.easeOut(duration: 0.12), value: viewModel.results.isEmpty)
        .dictionarySearchInput(viewModel: viewModel, locale: appLocale)
    }

    private var desktopStartState: some View {
        ScrollView {
            VStack(spacing: 36) {
                ContentUnavailableView(
                    AppLocalizer.text(.searchStartTitle, locale: appLocale),
                    systemImage: "text.magnifyingglass",
                    description: Text(AppLocalizer.text(.searchStartDescription, locale: appLocale))
                )
                .frame(maxWidth: 520)

                if !viewModel.searchHistory.isEmpty {
                    desktopSearchHistoryPanel
                }
            }
            .frame(maxWidth: 460)
            .padding(.horizontal, 32)
            .padding(.vertical, 56)
            .frame(maxWidth: .infinity)
        }
    }

    private func centeredState<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(24)
    }

    private var desktopSearchHistoryPanel: some View {
        GroupBox {
            VStack(spacing: 0) {
                ForEach(Array(viewModel.searchHistory.enumerated()), id: \.element) { index, query in
                    Button {
                        viewModel.applyHistoryQuery(query)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundStyle(.secondary)
                            Text(query)
                                .lineLimit(1)
                                .truncationMode(.tail)
                            Spacer(minLength: 12)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if index < viewModel.searchHistory.count - 1 {
                        Divider()
                            .padding(.leading, 38)
                    }
                }
            }
        } label: {
            HStack {
                Text(AppLocalizer.text(.searchHistoryTitle, locale: appLocale))
                    .font(.headline)
                Spacer()
                Button(role: .destructive) {
                    Task {
                        await viewModel.clearSearchHistory()
                    }
                } label: {
                    Label(AppLocalizer.text(.clearSearchHistory, locale: appLocale), systemImage: "trash")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.borderless)
            }
        }
        .frame(maxWidth: 420, alignment: .leading)
    }
}

extension View {
    @ViewBuilder
    func dictionarySearchInput(
        viewModel: DictionarySearchViewModel,
        locale: AppLocale
    ) -> some View {
#if os(macOS)
        self
#else
        searchable(text: Binding(
            get: { viewModel.searchText },
            set: { viewModel.searchText = $0 }
        ), prompt: AppLocalizer.text(.searchPrompt, locale: locale))
        .onChange(of: viewModel.searchText) { _, _ in
            viewModel.scheduleSearch()
        }
        .onSubmit(of: .search) {
            viewModel.submitSearch()
        }
#endif
    }
}

extension View {
    @ViewBuilder
    func taigiInlineNavigationTitle() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}
