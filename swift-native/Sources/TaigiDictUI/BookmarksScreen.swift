import SwiftUI
import TaigiDictCore

public struct BookmarksScreen: View {
    @State private var viewModel: BookmarksViewModel
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
            List {
                if viewModel.isLoading {
                    Section {
                        HStack {
                            ProgressView()
                            Text(AppLocalizer.text(.bookmarksLoading, locale: appLocale))
                        }
                    }
                } else if let errorMessage = viewModel.errorMessage {
                    Section {
                        ContentUnavailableView(
                            AppLocalizer.text(.loadingFailedTitle, locale: appLocale),
                            systemImage: "exclamationmark.triangle",
                            description: Text(errorMessage)
                        )
                    }
                } else if viewModel.entries.isEmpty {
                    Section {
                        ContentUnavailableView(
                            AppLocalizer.text(.bookmarksEmptyTitle, locale: appLocale),
                            systemImage: "bookmark",
                            description: Text(AppLocalizer.text(.bookmarksEmptyDescription, locale: appLocale))
                        )
                    }
                } else {
                    Section(AppLocalizer.text(.bookmarksSectionSaved, locale: appLocale)) {
                        ForEach(viewModel.entries) { entry in
                            Button {
                                viewModel.detailEntry = entry
                            } label: {
                                DictionaryEntryRowView(entry: entry)
                            }
                            .foregroundStyle(.primary)
                        }
                        .onDelete { offsets in
                            Task {
                                await viewModel.removeBookmarks(at: offsets)
                            }
                        }
                    }
                }
            }
            .navigationTitle(AppLocalizer.text(.bookmarksTitle, locale: appLocale))
            .navigationDestination(item: $viewModel.detailEntry) { entry in
                DictionaryDetailView(
                    entry: entry,
                    library: library,
                    bookmarkStore: bookmarkStore,
                    offlineAudioStore: offlineAudioStore,
                    conversionService: conversionService
                ) { _ in }
                .navigationTitle(entry.hanji)
                .taigiInlineNavigationTitle()
            }
        }
        .task {
            await viewModel.load()
        }
    }
}
