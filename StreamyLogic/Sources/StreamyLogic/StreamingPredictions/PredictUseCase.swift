import Foundation
import MetaWear
import CoreML
import MetaWearSync
import MetaWearCpp
import Combine
import simd


public class PredictUseCase: ObservableObject {
//    internal typealias StreamType = AnyPublisher<MWAccelerometer.DataType,MWError>
    internal typealias StreamType = AnyPublisher<MWSensorFusion.Quaternion.DataType,MWError>

    @Published public var prediction:     String            = ""
    @Published public var probabilities: [(String, Double)] = []
    @Published public var supportedOutputs:  [String]       = []
    @Published public var description:               String = ""

    @Published public private(set) var predictionRate: String       = "—"
    @Published public private(set) var frameRate:      String       = "—"
    @Published public var error:                       CoreMLError? = nil

    private var predictor:     CoreMLClassifierCoordinator? = nil
    private let queue:         DispatchQueue
    private weak var metawear: MetaWear?
    private var didSetup       = false

    private var streamSub:         AnyCancellable? = nil
    private var frameRateSub:      AnyCancellable? = nil
    private var reconnectSub:      AnyCancellable? = nil
    private var restartSub:        AnyCancellable? = nil
    private var predictionSubs:    Set<AnyCancellable> = []

    init(knownDevice: MWKnownDevice, queue: DispatchQueue) {
        self.queue = queue
        self.metawear = knownDevice.mw
    }

    func setPredictor(_ predictor: CoreMLClassifierCoordinator) {
        predictionSubs = []
        self.predictor = predictor
        DispatchQueue.main.async {
            self.description = predictor.description
            self.supportedOutputs = predictor.possibleClassifications
        }
        reportPredictions()
    }

    public func onAppear() {
        guard let stream = buildStreamPublisher(), !didSetup else { return }
        self.didSetup = true
        populateMLPredictor(with: stream)
        reportFrameRate(of: stream)

        restartSub = metawear?.publishWhenConnected().first()
            .stream(.mechanicalButton)
            .filter { $0.value == .up }
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] _ in
                self?.predictor?.resetData()
            })

        reconnectSub = metawear?.publishWhenDisconnected()
            .sink(receiveValue: { mw in mw.connect() })
    }

    internal func buildStreamPublisher() -> StreamType? {
        metawear?
            .publishWhenConnected()
            .first()
//            .stream(.accelerometer(rate: .hz100, gravity: .g16))
            .stream(.sensorFusionQuaternion(mode: .ndof))
            .map(\.value)
            .map(simd_quatf.init(vector:))
            .scan(simd_quatf(), { prior, current in
                if prior == simd_quatf() { return current }
                else { return current * prior.inverse }
            })
            .map(\.vector)
            .share()
            .eraseToAnyPublisher()
    }
}

private extension PredictUseCase {

    func populateMLPredictor(with stream: StreamType) {
        streamSub = stream
            .sink(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                DispatchQueue.main.async { [weak self] in
                    self?.error = .init(error: error)
                }
            }, receiveValue: { [weak self] in self?.predictor?.add(datum: $0) })

        metawear?.connect()
    }

    func reportFrameRate(of stream: StreamType) {
        frameRateSub = stream
            .map { _ in () }
            .receive(on: DispatchQueue.main)
            .collect(.byTime(DispatchQueue.main, 1))
            .map { $0.endIndex }
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] result in
                self?.frameRate = "\(result)"
            })
    }

    func reportPredictions() {
        predictor?.prediction
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] in self?.prediction = $0 })
            .store(in: &predictionSubs)

        predictor?.probabilities
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] in
                self?.probabilities = $0.map { ($0.key, $0.value) }.sortedByLetter
            })
            .store(in: &predictionSubs)

        predictor?.error
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] in
                self?.error = $0
            })
            .store(in: &predictionSubs)

        predictor?.probabilities
            .map { _ in () }
            .receive(on: queue)
            .collect(.byTime(queue, 1))
            .map { $0.endIndex }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] result in
                self?.predictionRate = "\(result)"
            })
            .store(in: &predictionSubs)
    }


}
