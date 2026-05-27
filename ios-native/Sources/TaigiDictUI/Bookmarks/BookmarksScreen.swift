import SwiftUI
import TaigiDictCore

public struct BookmarksScreen: View {
    @State private var viewModel: BookmarksViewModel
    @State private var selectedEntryIDs: Set<Int64> = []
    @State private var primarySelectedEntryID: Int64?
#if os(iOS)
    @State private var editMode: EditMode = .inactive
#endif
    @Environment(\.locale) private var locale
    private let library: DictionaryLibrary
    private let bookmarkStore: any BookmarksStoreProtocol
    private let offlineAudioStore: (any OfflineAudioManaging)?
    private let conversionService: (any ChineseConversionProviding)?

    public init(
        library: DictionaryLibrary,
        bookmarkStore: any BookmarksStoreProtocol,
        offlineAudioStore: (any OfflineAudioManaging)? = nil,
        conversionService: (any ChineseConversionProviding)? = nil
    ) {
        self.library = library
        self.bookmarkStore = bookmarkStore
        self.offlineAudioStore = offlineAudioStore
        self.conversionService = conversionService
        _viewModel = State(initialValue: BookmarksViewModel(library: library, bookmarkStore: bookmarkStore))
    }

    public var body: some View {
        let appLocale = AppLocalizer.appLocale(from: locale)
        bookmarksContainer(locale: appLocale)
        .task {
            await viewModel.load()
        }
    }

    @ViewBuilder
    private func bookmarksContainer(locale: AppLocale) -> some View {
#if os(macOS)
        NavigationSplitView {
            bookmarksRoot(locale: locale)
        } detail: {
            bookmarksDetail(locale: locale)
        }
        .navigationSplitViewStyle(.balanced)
#else
        NavigationStack {
            bookmarksRoot(locale: locale)
                .navigationDestination(for: DictionaryEntry.self) { entry in
                DictionaryDetailView(
                    entry: entry,
                    library: library,
                    bookmarkStore: bookmarkStore,
                    offlineAudioStore: offlineAudioStore,
                    conversionService: conversionService
                )
                .navigationTitle(entry.hanji)
                .taigiInlineNavigationTitle()
            }
        }
#endif
    }

    @ViewBuilder
    private func bookmarksRoot(locale: AppLocale) -> some View {
#if os(iOS)
        bookmarksList(locale: locale)
            .navigationTitle(AppLocalizer.text(.bookmarksTitle, locale: locale))
            .toolbar(isSelecting ? .hidden : .visible, for: .tabBar)
            .toolbar {
                if showsToolbarActions {
                    if isSelecting {
                        ToolbarItem(placement: .topBarLeading) {
                            selectAllToggleButton(locale: locale)
                        }

                        ToolbarItem(placement: .topBarTrailing) {
                            doneSelectingButton(locale: locale)
                        }
                    } else {
                        ToolbarItem(placement: .topBarTrailing) {
                            bookmarksMenu(locale: locale)
                        }
                    }
                }

                if showsToolbarActions && isSelecting {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Spacer()
                        deleteSelectedButton(locale: locale)
                        Spacer()
                    }
                }
            }
            .bookmarksSelectionBehavior(
                editMode: $editMode,
                selectedEntryIDs: $selectedEntryIDs,
                entryIDs: viewModel.entries.map(\.id)
            )
#else
        bookmarksDesktopList(locale: locale)
            .navigationTitle(AppLocalizer.text(.bookmarksTitle, locale: locale))
            .toolbar {
                if showsToolbarActions {
                    ToolbarItemGroup {
                        selectAllToggleButton(locale: locale)
                        deleteSelectedButton(locale: locale)
                    }
                }
            }
            .bookmarksSelectionBehavior(
                selectedEntryIDs: $selectedEntryIDs,
                primarySelectedEntryID: $primarySelectedEntryID,
                entryIDs: viewModel.entries.map(\.id)
            )
#endif
    }

    private var isSelecting: Bool {
#if os(iOS)
        editMode.isEditing
#else
        false
#endif
    }

    private var showsToolbarActions: Bool {
        !viewModel.isLoading && viewModel.errorMessage == nil && !viewModel.entries.isEmpty
    }

    private var selectionBinding: Binding<Set<Int64>> {
        Binding(
            get: {
                isSelecting ? selectedEntryIDs : []
            },
            set: { newValue in
                selectedEntryIDs = newValue.intersection(Set(viewModel.entries.map(\.id)))
            }
        )
    }

    private var selectedBookmarkEntry: DictionaryEntry? {
        guard let selectedID = resolvedPrimarySelectedEntryID else {
            return nil
        }

        return viewModel.entries.first { $0.id == selectedID }
    }

    private var resolvedPrimarySelectedEntryID: Int64? {
        if let primarySelectedEntryID,
           selectedEntryIDs.contains(primarySelectedEntryID) {
            return primarySelectedEntryID
        }

        return viewModel.entries.first { selectedEntryIDs.contains($0.id) }?.id
    }

    @ViewBuilder
    private func bookmarksList(locale: AppLocale) -> some View {
        if isSelecting {
            List(selection: selectionBinding) {
                bookmarksContent(locale: locale, isSelecting: true)
            }
        } else {
            List {
                bookmarksContent(locale: locale, isSelecting: false)
            }
        }
    }

#if os(macOS)
    @ViewBuilder
    private func bookmarksDesktopList(locale: AppLocale) -> some View {
        List(selection: $selectedEntryIDs) {
            bookmarksContent(locale: locale, isSelecting: true)
        }
    }

    @ViewBuilder
    private func bookmarksDetail(locale: AppLocale) -> some View {
        if let selectedBookmarkEntry {
            DictionaryDetailView(
                entry: selectedBookmarkEntry,
                library: library,
                bookmarkStore: bookmarkStore,
                offlineAudioStore: offlineAudioStore,
                conversionService: conversionService
            )
            .navigationTitle(selectedBookmarkEntry.hanji)
        } else {
            ContentUnavailableView(
                AppLocalizer.text(.searchStartDetailTitle, locale: locale),
                systemImage: "bookmark",
                description: Text(AppLocalizer.text(.bookmarksEmptyDescription, locale: locale))
            )
        }
    }
#endif

    @ViewBuilder
    private func bookmarksContent(locale: AppLocale, isSelecting: Bool) -> some View {
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
        } else if viewModel.entries.isEmpty {
            Section {
                ContentUnavailableView(
                    AppLocalizer.text(.bookmarksEmptyTitle, locale: locale),
                    systemImage: "bookmark",
                    description: Text(AppLocalizer.text(.bookmarksEmptyDescription, locale: locale))
                )
            }
        } else {
            Section(AppLocalizer.text(.bookmarksSectionSaved, locale: locale)) {
                ForEach(viewModel.entries) { entry in
                    if isSelecting {
                        DictionaryEntryRowView(entry: entry, layoutStyle: .sidebarCompact)
                            .tag(entry.id)
#if os(macOS)
                            .contextMenu {
                                Button(role: .destructive) {
                                    Task {
                                        await removeBookmarks(entryIDs: [entry.id])
                                    }
                                } label: {
                                    Label(AppLocalizer.text(.commonDelete, locale: locale), systemImage: "trash")
                                }

                                ShareLink(item: WordDetailViewModel.shareText(for: entry)) {
                                    Label(AppLocalizer.text(.share, locale: locale), systemImage: "square.and.arrow.up")
                                }
                            }
#endif
                    } else {
                        NavigationLink(value: entry) {
                            DictionaryEntryRowView(entry: entry)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task {
                                    await viewModel.removeBookmark(entryID: entry.id)
                                }
                            } label: {
                                Label(AppLocalizer.text(.commonDelete, locale: locale), systemImage: "trash")
                            }

                            ShareLink(item: WordDetailViewModel.shareText(for: entry)) {
                                Label(AppLocalizer.text(.share, locale: locale), systemImage: "square.and.arrow.up")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
        }
    }

    private func selectAllButton(locale: AppLocale) -> some View {
        Button(AppLocalizer.text(.bookmarksSelectAll, locale: locale)) {
            selectedEntryIDs = Set(viewModel.entries.map(\.id))
            primarySelectedEntryID = viewModel.entries.first?.id
        }
        .disabled(areAllBookmarksSelected)
    }

    private func deselectAllButton(locale: AppLocale) -> some View {
        Button(AppLocalizer.text(.bookmarksDeselectAll, locale: locale)) {
            selectedEntryIDs = []
            primarySelectedEntryID = nil
        }
        .disabled(!hasSelection)
    }

    @ViewBuilder
    private func selectAllToggleButton(locale: AppLocale) -> some View {
        if areAllBookmarksSelected {
            deselectAllButton(locale: locale)
        } else {
            selectAllButton(locale: locale)
        }
    }

    private func doneSelectingButton(locale: AppLocale) -> some View {
        Button {
            selectedEntryIDs = []
            primarySelectedEntryID = nil
#if os(iOS)
            editMode = .inactive
#endif
        } label: {
            Image(systemName: "checkmark")
        }
        .accessibilityLabel(AppLocalizer.text(.bookmarksDoneSelecting, locale: locale))
    }

    private func bookmarksMenu(locale: AppLocale) -> some View {
        Menu {
            Button(AppLocalizer.text(.bookmarksSelect, locale: locale)) {
                selectedEntryIDs = []
                primarySelectedEntryID = nil
#if os(iOS)
                editMode = .active
#endif
            }
        } label: {
            Image(systemName: "ellipsis")
        }
        .accessibilityLabel(AppLocalizer.text(.settingsActionsMenu, locale: locale))
    }

    private func deleteSelectedButton(locale: AppLocale) -> some View {
        Button(AppLocalizer.text(.bookmarksDeleteSelected, locale: locale), role: .destructive) {
            Task {
                await removeBookmarks(entryIDs: selectedEntryIDs)
#if os(iOS)
                editMode = .inactive
#endif
            }
        }
        .disabled(!hasSelection)
    }

    private var hasSelection: Bool {
        !selectedEntryIDs.isEmpty
    }

    private var areAllBookmarksSelected: Bool {
        !viewModel.entries.isEmpty && selectedEntryIDs.count == viewModel.entries.count
    }

    private func removeBookmarks(entryIDs: Set<Int64>) async {
        let idsToRemove = entryIDs
        selectedEntryIDs = []
        primarySelectedEntryID = nil
        await viewModel.removeBookmarks(entryIDs: idsToRemove)
    }
}

private extension View {
#if os(iOS)
    @ViewBuilder
    func bookmarksEditMode(_ editMode: Binding<EditMode>) -> some View {
        self.environment(\.editMode, editMode)
    }

    @ViewBuilder
    func bookmarksSelectionBehavior(
        editMode: Binding<EditMode>,
        selectedEntryIDs: Binding<Set<Int64>>,
        entryIDs: [Int64]
    ) -> some View {
        self
            .bookmarksEditMode(editMode)
            .onChange(of: editMode.wrappedValue) { _, newValue in
                if !newValue.isEditing {
                    selectedEntryIDs.wrappedValue = []
                }
            }
            .onChange(of: entryIDs) { _, newIDs in
                selectedEntryIDs.wrappedValue.formIntersection(Set(newIDs))
                if newIDs.isEmpty {
                    editMode.wrappedValue = .inactive
                }
            }
    }
#else
    @ViewBuilder
    func bookmarksSelectionBehavior(
        selectedEntryIDs: Binding<Set<Int64>>,
        primarySelectedEntryID: Binding<Int64?>,
        entryIDs: [Int64]
    ) -> some View {
        self
            .onChange(of: selectedEntryIDs.wrappedValue) { _, newSelection in
                if newSelection.isEmpty {
                    primarySelectedEntryID.wrappedValue = nil
                } else if let currentPrimary = primarySelectedEntryID.wrappedValue,
                          newSelection.contains(currentPrimary) {
                    return
                } else {
                    primarySelectedEntryID.wrappedValue = entryIDs.first { newSelection.contains($0) }
                }
            }
            .onChange(of: entryIDs) { _, newIDs in
                let validIDs = Set(newIDs)
                selectedEntryIDs.wrappedValue.formIntersection(validIDs)
                if let currentPrimary = primarySelectedEntryID.wrappedValue,
                   !validIDs.contains(currentPrimary) {
                    primarySelectedEntryID.wrappedValue = newIDs.first { selectedEntryIDs.wrappedValue.contains($0) }
                }
            }
    }
#endif
}
