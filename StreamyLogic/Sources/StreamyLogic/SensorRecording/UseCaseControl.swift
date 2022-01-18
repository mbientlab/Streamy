import Foundation
import Combine
import MetaWear

/// Represents the offered case to the user.
///
public enum UseCaseCTA: String {
    case connect, configure, log, download, export

    public var displayName: String {
        switch self {
            case .configure: return "New Session"
            case .log:       return "Start Logging"
            case .download:  return "Download Data"
            case .export:    return "Export"
            case .connect:   return "Connecting"
        }
    }
}

/// Represents the current progress, positive or negative, for completing a sensor recording use case.
///
public enum UseCaseState {
    case ready, workingIndefinite, workingProgress(Double)
    case notReady, error(Error)

    public var isWorking: Bool {
        switch self {
            case .workingIndefinite: return true
            case .workingProgress: return true
            default: return false
        }
    }

    public var isReady: Bool { self == .ready }
}

extension UseCaseState: Equatable, Comparable {

    fileprivate var rank: Double {
        switch self {
            case .error: return -2
            case .notReady: return -1
            case .workingIndefinite: return 0
            case .workingProgress(let percent): return percent
            case .ready: return 2
        }
    }

    public static func < (lhs: UseCaseState, rhs: UseCaseState) -> Bool {
        lhs.rank < rhs.rank
    }

    public static func == (lhs: UseCaseState, rhs: UseCaseState) -> Bool {
        switch (lhs, rhs) {
            case (.notReady, .notReady), (.ready, .ready), (.workingIndefinite, .workingIndefinite), (.workingProgress, .workingProgress): return true
            case (.error(let lhs), .error(let rhs)): return lhs.localizedDescription == rhs.localizedDescription
            default: return false
        }
    }
}
