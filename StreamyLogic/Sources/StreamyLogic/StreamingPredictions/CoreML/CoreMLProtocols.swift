import Foundation
import CoreML
import Combine

/// Feeds and obtains predictions from one CoreML model. Must have a matching input data type and requirements.
///
/// **Thread Safety** Use and create a CoreML model only on one background queue.
///
protocol CoreMLClassifierCoordinator {
    func add(datum: [Float])
    func resetData()

    var prediction:    CurrentValueSubject<String, Never>           { get }
    var probabilities: CurrentValueSubject<[String:Double], Never>  { get }
    var error:         CurrentValueSubject<CoreMLError?, Never>     { get }

    var predictionWindowWidth:    Int     { get }
    var possibleClassifications: [String] { get }
    var description:              String  { get }
}

/// Errors from using CoreML
///
public enum CoreMLError: Error, LocalizedError, Equatable {
    case noModelsMatchDeviceCapabilities
    case unexpectedModelParameters
    case invalidDataInputType
    case unexpectedOutput
    case unknown(Error)

    public var errorDescription: String? {
        switch self {
            case .noModelsMatchDeviceCapabilities: return "Your MetaWear doesn't support this CoreML model's required inputs."
            case .unexpectedModelParameters: return "Your CoreML model contains parameters unsupported by the controller attempting to initialize with this model. Write a new controller class."
            case .invalidDataInputType: return "This CoreML coordinator requires a different data type."
            case .unexpectedOutput: return "CoreML output unexpected"
            case .unknown(let error): return error.localizedDescription
        }
    }

    public init(error: Error) {
        if let error = error as? CoreMLError { self = error }
        else { self = .unknown(error) }
    }

    public static func == (lhs: CoreMLError, rhs: CoreMLError) -> Bool {
        lhs.localizedDescription == rhs.localizedDescription
    }
}
