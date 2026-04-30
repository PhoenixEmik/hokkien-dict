import Foundation
import Observation
import TaigiDictCore

@MainActor
@Observable
public final class InitializationViewModel {
    public enum State: Equatable {
        case idle
        case loading
        case ready
        case failed(String)
    }

    public private(set) var state: State = .idle
    public private(set) var taskID = UUID()

    public init() {}

    public func prepare(using searchViewModel: DictionarySearchViewModel) async {
        state = .loading
        await searchViewModel.load()

        switch searchViewModel.libraryPhase {
        case .ready:
            state = .ready
        case .failed(let message):
            state = .failed(message)
        case .idle, .loading:
            state = .failed("辭典初始化流程未完成。")
        }
    }

    public func retry() {
        state = .idle
        taskID = UUID()
    }
}