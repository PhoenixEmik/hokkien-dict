import SwiftUI
import TaigiDictCore

public struct BookmarksScreen: View {
    @State private var viewModel: BookmarksViewModel
    @State private var selectedEntryIDs: Set<Int64> = []
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
        NavigationStack {
            bookmarksRoot(locale: appLocale)
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
        .task {
            await viewModel.load()
        }
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
        bookmarksList(locale: locale)
            .navigationTitle(AppLocalizer.text(.bookmarksTitle, locale: locale))
            .bookmarksSelectionBehavior(
                selectedEntryIDs: $selectedEntryIDs,
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
        }
        .disabled(areAllBookmarksSelected)
    }

    private func deselectAllButton(locale: AppLocale) -> some View {
        Button(AppLocalizer.text(.bookmarksDeselectAll, locale: locale)) {
            selectedEntryIDs = []
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
                let idsToRemove = selectedEntryIDs
                selectedEntryIDs = []
                await viewModel.removeBookmarks(entryIDs: idsToRemove)
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
        entryIDs: [Int64]
    ) -> some View {
        self.onChange(of: entryIDs) { _, newIDs in
            selectedEntryIDs.wrappedValue.formIntersection(Set(newIDs))
        }
    }
#endif
}
