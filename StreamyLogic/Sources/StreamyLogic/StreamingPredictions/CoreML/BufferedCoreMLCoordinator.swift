import Foundation
import CoreML
import Combine
import MetaWear

/// Buffers streaming motion data in SIMD3 or SIMD4 format.
///
/// This class drives multiple separate model prediction pipelines with overlapping timeframes to increase accuracy and improve responsiveness. To do so, you'll see some sliding window business that composes and gates use of input data buffers and multiple recurrent layer states.
///
class BufferedCoreMLCoordinator: CoreMLClassifierCoordinator {

    /// Every 5 data points, current data is sliced and sent for prediction. This increases model predictive potential and apparent responsiveness.
    ///
    /// - Parameters:
    ///   - model: CoreML model constructed on the queue provided
    ///   - queue: Queue for all operations with the CoreML model
    ///   - vectorLabels: Labels for the SIMD3 or 4 streaming data vector, in case they differ from XYZW in your CoreML feature names
    ///
    init(model: MLModel, queue: DispatchQueue) throws {
        DispatchQueue.assertOnCoreMLQueue()

        self.model = model
        self.queue = queue

        // Public output description
        self.description = model.modelDescription.metadata[.description] as? String ?? ""
        self.possibleClassifications = model.modelDescription.classLabels?.compactMap { $0 as? String } ?? []
        (self.inputFeatureNames, self.outputFeatureNames, self.inputVectorOrderedLabels) = model.featureNames()

        // Internal description of model features
        guard let shape = model.getShape() else { throw CoreMLError.unexpectedModelParameters }
        self.predictionWindowWidth = Int(shape.predictionWindow)
        self.slidingWindowOffset   = 10
        self.slidingWindows        = (predictionWindowWidth / slidingWindowOffset)
        let bufferWidth            = predictionWindowWidth + (slidingWindows - 1) * slidingWindowOffset
        self.bufferWidth           = bufferWidth

        // Setup data collectors and recurrent layer cache
        self.inputBuffers = inputFeatureNames.reduce(into: [FeatureName:MLMultiArray](), { dict, name in
            dict[name] = try! .init(singleRowSize: bufferWidth, dataType: .double)
        })
        (self.lstmStates, self.inputFeatureProviders) = ([], [])
        self.lstmStates.reserveCapacity(slidingWindows)
        self.inputFeatureProviders.reserveCapacity(slidingWindows)
        for windowIndex in 0..<slidingWindows {
            self.lstmStates.append(try! .init(singleRowSize: shape.lstmStateSize, dataType: .double))
            self.inputFeatureProviders.append(.init(slidingWindowIndex: windowIndex, parent: self))
        }
    }

    // Output
    let prediction = CurrentValueSubject<String,Never>("")
    let probabilities = CurrentValueSubject<[String:Double],Never>([:])
    let error = CurrentValueSubject<CoreMLError?,Never>(nil)

    // Description of outputs
    let possibleClassifications: [String]
    let description: String

    /// Labels of the fields exchanged with CoreML
    internal let (inputFeatureNames, outputFeatureNames): (Set<FeatureName>, Set<FeatureName>)
    private let inputVectorOrderedLabels: [FeatureName]
    typealias FeatureName     = String

    // Shape of data arrays
    internal let predictionWindowWidth: Int
    private  let slidingWindowOffset:   Int
    private  let slidingWindows:        Int
    private  let bufferWidth:           Int
    private  var predictionWindowIndex  = 0

    // Buffer of data and recent recurrent layer states
    private var lstmStates:                [MLMultiArray]
    private var inputBuffers:              [FeatureName : MLMultiArray]
    private var inputFeatureProviders:     [BufferedFeatureProvider]
    private var bufferDidFill              = false

    // Dependencies
    private let model: MLModel
    private var queue: DispatchQueue

    /// Reset all CoreML pipeline's state
    func resetData() {
        queue.async { [self] in
            self.bufferDidFill = false
            self.predictionWindowIndex = 0
            self.inputBuffers.values.forEach { $0.zeroOut() }
            self.lstmStates.forEach { $0.zeroOut() }
        }
    }

    /// Add data point to the queue and trigger a prediction if ready.
    func add(datum: [Float]) {
        queue.async { [weak self] in
            self?.add(vector: datum)
        }
    }
}

private extension BufferedCoreMLCoordinator {

    func add(vector: [Float]) {
        DispatchQueue.assertOnCoreMLQueue()

        // For each value in the SIMD vector (e.g., XYZW)
        for i in inputVectorOrderedLabels.indices {
            let label = inputVectorOrderedLabels[i]
            let datum = vector[i]
            // Set this value in the first half of the input buffer
            inputBuffers[label]?[[predictionWindowIndex] as [NSNumber]] = datum as NSNumber

            // Also set this value in the second half of the input buffer, which is slightly shorter than the first half
            let secondBufferIndex = predictionWindowIndex + predictionWindowWidth
            if secondBufferIndex < bufferWidth {
                inputBuffers[label]?[[secondBufferIndex] as [NSNumber]] = datum as NSNumber
            }
        }

        predictionWindowIndex += 1

        // If the data buffer is full enough for a prediction, flag this has occurred. Then wrap the index pointer back to zero, so the buffer fills from both the front and middle (as above).
        if predictionWindowIndex == predictionWindowWidth {
            bufferDidFill = true
            predictionWindowIndex = 0
        }
        // If the buffer has been marked as filled in the past and the current index is at zero or an offset that matches sliding window offset, schedule a prediction.
        guard bufferDidFill && predictionWindowIndex % slidingWindowOffset == 0 else { return }
        predict()
    }

    /// Perform a prediction and broadcast the results
    func predict() {
        // Get the object capable of slicing the right data for this sliding window
        let currentWindow = predictionWindowIndex / slidingWindowOffset
        let bufferWindowFeatureProvider = inputFeatureProviders[currentWindow]

        do {
            // Provide CoreML with the data-producing object
            let output = try model.prediction(from: bufferWindowFeatureProvider)

            // Extract CoreML's prediction(s)
            self.lstmStates[currentWindow] = output.featureValue(for: "stateOut")!.multiArrayValue!
            let prediction = output.featureValue(for: "label")!.stringValue
            let probabilities = output.featureValue(for: "labelProbability")!.dictionaryValue

            // Share these data (or error)
            if let probabilities = probabilities as? [String : Double] {
                self.prediction.value = prediction
                self.probabilities.value = probabilities.mapValues { $0.isNaN ? 0 : $0 }
            } else { self.error.value = .unexpectedOutput }
        } catch { self.error.value = .unknown(error) }
    }
}

extension BufferedCoreMLCoordinator: ParentMLFeatureProvider {

    /// Slice the 1D buffer array appropriately for the current sliding window, using a pointer to copy the stored data
    ///
    func getFeature(named: String, forSlidingWindow index: Int) -> MLFeatureValue? {
        switch named {
            case "stateIn":
                return .init(multiArray: lstmStates[index])

            default:
                let offsetIndex = index * self.slidingWindowOffset
                let slice = try! inputBuffers[named]!.sliceValues(fromIndex: offsetIndex, width: predictionWindowWidth)
                return .init(multiArray: slice)
        }
    }
}
