import Foundation
import Observation
import TaigiDictCore

public enum InitializationPhase: Equatable, Sendable {
    case idle
    case loading
    case ready
    case failed
}

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

    public private(set) var phase: InitializationPhase = .idle
    public private(set) var progress: Double?
    public private(set) var processedUnits = 0
    public private(set) var totalUnits = 0
    public private(set) var errorMessage: String?
    public private(set) var failureReason: FailureReason?
    public private(set) var databaseGeneration = 0
    public private(set) var taskID = UUID()

    public var isReady: Bool {
        phase == .ready
    }

    public var state: State {
        switch phase {
        case .idle:
            return .idle
        case .loading:
            return .loading
        case .ready:
            return .ready
        case .failed:
            return .failed(failureReason ?? .initializationIncomplete)
        }
    }

    public init() {}

    public func prepare(using searchViewModel: DictionarySearchViewModel) async {
        let previousPhase = phase
        phase = .loading
        processedUnits = 0
        totalUnits = 1
        progress = 0
        errorMessage = nil
        failureReason = nil

        await searchViewModel.load()
        processedUnits = 1
        progress = 1

        switch searchViewModel.libraryPhase {
        case .ready:
            phase = .ready
            if previousPhase != .ready {
                databaseGeneration += 1
            }
        case .failed(let message):
            phase = .failed
            failureReason = .library(message)
            errorMessage = message
        case .idle, .loading:
            phase = .failed
            failureReason = .initializationIncomplete
        }
    }

    public func retry() {
        phase = .idle
        progress = nil
        processedUnits = 0
        totalUnits = 0
        errorMessage = nil
        failureReason = nil
        taskID = UUID()
    }
}