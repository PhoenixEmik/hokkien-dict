import Foundation
import Observation
import TaigiDictCore

@MainActor
@Observable
public final class InitializationViewModel {
    public enum FailureReason: Equatable {
        case library(String)
        case initializationIncomplete
    }

    public enum State: Equatable {
        case idle
        case loading
        case ready
        case failed(FailureReason)
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
            state = .failed(.library(message))
        case .idle, .loading:
            state = .failed(.initializationIncomplete)
        }
    }

    public func retry() {
        state = .idle
        taskID = UUID()
    }
}