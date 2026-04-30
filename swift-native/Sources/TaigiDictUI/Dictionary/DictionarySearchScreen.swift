import SwiftUI
import TaigiDictCore

public struct DictionarySearchScreen: View {
    @Bindable private var viewModel: DictionarySearchViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.locale) private var locale
    private let bookmarkStore: (any BookmarksStoreProtocol)?
    private let offlineAudioStore: (any OfflineAudioManaging)?
    private let conversionService: (any ChineseConversionProviding)?

    public init(
        viewModel: DictionarySearchViewModel,
        bookmarkStore: (any BookmarksStoreProtocol)? = nil,
        offlineAudioStore: (any OfflineAudioManaging)? = nil,
        conversionService: (any ChineseConversionProviding)? = nil
    ) {
        _viewModel = Bindable(viewModel)
        self.bookmarkStore = bookmarkStore
        self.offlineAudioStore = offlineAudioStore
        self.conversionService = conversionService
    }

    private var appLocale: AppLocale {
        AppLocalizer.appLocale(from: locale)
    }

    public var body: some View {
        if horizontalSizeClass == .regular {
            NavigationSplitView {
                DictionarySearchListView(viewModel: viewModel, showsSelection: true)
                    .navigationTitle(AppLocalizer.text(.dictionaryTitle, locale: appLocale))
            } detail: {
                DictionaryDetailView(
                    entry: viewModel.selectedEntry,
                    library: viewModel.library,
                    bookmarkStore: bookmarkStore,
                    offlineAudioStore: offlineAudioStore,
                    conversionService: conversionService
                ) { entry in
                    viewModel.select(entry)
                }
                .navigationTitle(viewModel.selectedEntry?.hanji ?? AppLocalizer.text(.dictionaryTitle, locale: appLocale))
            }
        } else {
            NavigationStack {
                DictionarySearchListView(viewModel: viewModel, showsSelection: false)
                    .navigationTitle(AppLocalizer.text(.dictionaryTitle, locale: appLocale))
                    .navigationDestination(item: $viewModel.detailEntry) { entry in
                        DictionaryDetailView(
                            entry: entry,
                            library: viewModel.library,
                            bookmarkStore: bookmarkStore,
                            offlineAudioStore: offlineAudioStore,
                            conversionService: conversionService
                        ) { linkedEntry in
                            viewModel.select(linkedEntry)
                        }
                        .navigationTitle(entry.hanji)
                        #if os(iOS)
                        .navigationBarTitleDisplayMode(.inline)
                        #endif
                    }
            }
        }
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
