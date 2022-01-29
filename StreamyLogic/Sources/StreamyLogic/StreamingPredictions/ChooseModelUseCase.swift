import Foundation
import Combine
import MetaWear
import MetaWearSync

public class ChooseModelUseCase: ObservableObject {

    @Published public var choice = "" {
        willSet { select(model: newValue) }
    }
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
        self.predictor = PredictUseCase(knownDevice: knownDevice, queue: queue)
    }
}

public extension ChooseModelUseCase {

    func onAppear() {
        DispatchQueue.main.async {
            self.modelChoices = self.vendor.enumerateModels()
        }
    }

    func select(model name: String) {
        isLoading = true
        let queue = self.queue

        buildModelSub = vendor
            .getCompiledModel(name: name, for: metadata, on: queue)
            .tryMap { model -> CoreMLClassifierCoordinator in
                try BufferedCoreMLCoordinatorForSIMD34(model: model, queue: queue, vectorLabels: ["X", "Y", "Z", "W"])
            }
            .sink { [weak self] completion in
                DispatchQueue.main.async { [weak self] in
                    self?.isLoading = false
                    guard case let .failure(error) = completion else { return }
                    self?.error = .init(error: error)
                }

            } receiveValue: { [weak self] result in
                self?.predictor.setPredictor(result)
            }
    }
}
