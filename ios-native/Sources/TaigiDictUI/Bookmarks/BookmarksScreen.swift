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
            content(appLocale: appLocale)
            .navigationTitle(AppLocalizer.text(.bookmarksTitle, locale: appLocale))
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
    private func content(appLocale: AppLocale) -> some View {
        if viewModel.isLoading {
            placeholderContainer {
                HStack(spacing: 12) {
                    ProgressView()
                    Text(AppLocalizer.text(.bookmarksLoading, locale: appLocale))
                        .foregroundStyle(.secondary)
                }
            }
        } else if let errorMessage = viewModel.errorMessage {
            placeholderContainer {
                ContentUnavailableView(
                    AppLocalizer.text(.loadingFailedTitle, locale: appLocale),
                    systemImage: "exclamationmark.triangle",
                    description: Text(errorMessage)
                )
            }
        } else if viewModel.entries.isEmpty {
            placeholderContainer {
                ContentUnavailableView(
                    AppLocalizer.text(.bookmarksEmptyTitle, locale: appLocale),
                    systemImage: "bookmark",
                    description: Text(AppLocalizer.text(.bookmarksEmptyDescription, locale: appLocale))
                )
            }
        } else {
            List {
                ForEach(viewModel.entries) { entry in
                    NavigationLink(value: entry) {
                        DictionaryEntryRowView(entry: entry)
                            .padding(.vertical, 4)
                    }
                }
                .onDelete { offsets in
                    Task {
                        await viewModel.removeBookmarks(at: offsets)
                    }
                }
            }
            #if os(iOS)
            .listStyle(.plain)
            #endif
        }
    }

    private func placeholderContainer<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
    }
}
