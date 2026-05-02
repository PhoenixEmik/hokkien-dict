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
        let dictionaryTitle = AppLocalizer.text(.dictionaryTitle, locale: appLocale)
        let searchTitle = AppLocalizer.text(.searchTitle, locale: appLocale)

        switch DictionarySearchPresentation.resolve(horizontalSizeClass: horizontalSizeClass) {
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
}

enum DictionarySearchNavigationTitle {
    static func detailTitle(selectedEntryHanji: String?, dictionaryTitle: String) -> String {
        dictionaryTitle
    }
}

enum DictionarySearchPresentation: Equatable {
    case compactStack
    case regularSplit

    static func resolve(horizontalSizeClass: UserInterfaceSizeClass?) -> DictionarySearchPresentation {
        horizontalSizeClass == .regular ? .regularSplit : .compactStack
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
