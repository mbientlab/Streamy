import Foundation
import CoreML
import MetaWear
import MetaWearSync
import Combine

/// Finds available CoreML models matching a device's capabilities.
///
public protocol CoreMLModelVendor {
    func enumerateModels() -> [String]
    func getCompiledModel(name: String, for device: MetaWearMetadata, on queue: DispatchQueue) -> AnyPublisher<MLModel, CoreMLError>
}

/// Finds models in the StreamyLogic bundle or application support folder. Compiles them if needed.
///
/// Just drop uncompiled `.mlmodel` files into the `CoreML/Models` directory of the Streamy Logic package.
///
public struct LocalBundleCoreMLModelVendor {

    var requiredSensors: Set<MWModules.ID>

    private let compileDirectory = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask)
        .first!

    public init(sensors: Set<MWModules.ID>) {
        self.requiredSensors = sensors
    }
}

extension LocalBundleCoreMLModelVendor: CoreMLModelVendor {

    public func enumerateModels() -> [String] {
        Bundle.module
            .urls(forResourcesWithExtension: "mlmodel", subdirectory: nil)
            .map { $0.compactMap { $0.deletingPathExtension().lastPathComponent } }
        ?? []
    }

    public func getCompiledModel(name: String, for device: MetaWearMetadata, on queue: DispatchQueue) -> AnyPublisher<MLModel,CoreMLError> {

        guard Set(device.modules.keys).isSuperset(of: requiredSensors) else {
            return Fail(
                outputType: MLModel.self,
                failure: CoreMLError.noModelsMatchDeviceCapabilities
            ).eraseToAnyPublisher()
        }

        return Just(compiledURL(for: name))
            .receive(on: queue)
            .tryMap { url -> URL in
                guard FileManager.default.isReadableFile(atPath: url.path) else {
                    let newCompilationURL = try MLModel.compileModel(at: resourceURL(for: name))
                    _ = try FileManager.default.replaceItemAt(url, withItemAt: newCompilationURL)
                    return url
                }
                return url
            }
            .tryMap { url -> MLModel in
                DispatchQueue.assertOnCoreMLQueue()
                return try MLModel(contentsOf: url)
            }
            .subscribe(on: queue)
            .mapError { CoreMLError(error: $0) }
            .eraseToAnyPublisher()
    }

    private func compiledURL(for modelName: String) -> URL {
        compileDirectory
            .appendingPathComponent(modelName)
            .appendingPathExtension("mlmodelc")
    }

    private func resourceURL(for modelName: String) -> URL {
        Bundle.module.url(forResource: modelName, withExtension: "mlmodel")!
    }
}
