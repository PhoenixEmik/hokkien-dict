import SwiftUI
import TaigiDictCore

public struct TaigiDictAppRootView: View {
    @State private var viewModel: DictionarySearchViewModel
    @State private var initializationViewModel = InitializationViewModel()

    public init(repository: any DictionaryRepositoryProtocol) {
        _viewModel = State(initialValue: DictionarySearchViewModel(repository: repository))
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
    }

    private var mainTabView: some View {
        TabView {
            DictionarySearchScreen(viewModel: viewModel)
                .tabItem {
                    Label("辭典", systemImage: "book")
                }

            PlaceholderScreen(
                title: "書籤",
                systemImage: "bookmark",
                message: "書籤功能會在後續重構接入。"
            )
            .tabItem {
                Label("書籤", systemImage: "bookmark")
            }

            SettingsScreen(library: viewModel.library) {
                Task { @MainActor in
                    await viewModel.resetAfterMaintenance()
                    initializationViewModel.retry()
                }
            }
            .tabItem {
                Label("設定", systemImage: "gearshape")
            }
        }
    }
}

private struct PlaceholderScreen: View {
    var title: String
    var systemImage: String
    var message: String

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                title,
                systemImage: systemImage,
                description: Text(message)
            )
            .navigationTitle(title)
        }
    }
}
