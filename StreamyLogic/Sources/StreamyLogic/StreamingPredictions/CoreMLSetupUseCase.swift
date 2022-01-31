import Foundation
import Combine
import MetaWear
import MetaWearSync

public class CoreMLSetupUseCase: ObservableObject {

    @Published public var sensor: SensorStreamForCoreML
    public let sensorChoices      = SensorStreamForCoreML.allCases
    @Published public var model   = ""
    @Published public private(set) var modelChoices: [String]        = []
    @Published public private(set) var isLoading:    Bool            = false
    @Published public var error:                     CoreMLError?    = nil
    public let predictor: PredictUseCase

    private weak var metawear: MetaWear?
    private let metadata:      MetaWearMetadata
    private let vendor:        CoreMLModelVendor
    private var buildModelSub: AnyCancellable? = nil
    private let queue: DispatchQueue

    public init(_ knownDevice: MWKnownDevice, _ vendor: CoreMLModelVendor) {
        self.vendor = vendor
        self.metawear = knownDevice.mw
        self.metadata = knownDevice.meta
        let queue = DispatchQueue(label: Bundle.main.bundleIdentifier! + ".\(Self.self)")
        queue.markAsCoreMLQueue()
        self.queue = queue
        let sensor = SensorStreamForCoreML.quaternionDeltas
        self.sensor = sensor
        self.predictor = PredictUseCase(knownDevice: knownDevice, queue: queue, stream: sensor)
    }
}

public extension CoreMLSetupUseCase {

    func onAppear() {
        DispatchQueue.main.async {
            self.modelChoices = self.vendor.enumerateModels()
            if self.model == "" { self.model = self.modelChoices.first ?? "" }
        }
    }

    func startModel() {
        guard model != "", isLoading == false else { return }
        isLoading = true
        let queue = self.queue
        let stream = sensor

        buildModelSub = vendor
            .getCompiledModel(name: model, for: metadata, on: queue)
            .tryMap { model -> CoreMLClassifierCoordinator in
                try BufferedCoreMLCoordinator(model: model, queue: queue)
            }
            .sink { [weak self] completion in
                DispatchQueue.main.async { [weak self] in
                    self?.isLoading = false
                    guard case let .failure(error) = completion else { return }
                    self?.error = .init(error: error)
                }

            } receiveValue: { [weak self] result in
                self?.predictor.setPredictor(result, stream)
            }
    }
}
