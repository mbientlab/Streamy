import Foundation
import MetaWear
import CoreML
import MetaWearSync
import MetaWearCpp
import Combine
import simd

public class PredictUseCase: ObservableObject {

    @Published public var prediction:        String             = ""
    @Published public var probabilities:     [(String, Double)] = []
    @Published public var supportedOutputs:  [String]           = []
    @Published public var description:       String             = ""

    @Published public private(set) var predictionRate: String       = "—"
    @Published public private(set) var frameRate:      String       = "—"
    @Published public var error:                       CoreMLError? = nil

    private var stream:        SensorStreamForCoreML
    private var predictor:     CoreMLClassifierCoordinator? = nil
    private let queue:         DispatchQueue
    private weak var metawear: MetaWear?
    private var didSetup       = false

    private var streamSub:         AnyCancellable? = nil
    private var frameRateSub:      AnyCancellable? = nil
    private var reconnectSub:      AnyCancellable? = nil
    private var restartSub:        AnyCancellable? = nil
    private var predictionSubs:    Set<AnyCancellable> = []

    init(knownDevice: MWKnownDevice, queue: DispatchQueue, stream: SensorStreamForCoreML) {
        self.queue = queue
        self.metawear = knownDevice.mw
        self.stream = stream
    }

    func setPredictor(_ predictor: CoreMLClassifierCoordinator, _ sensorStream: SensorStreamForCoreML) {

        if sensorStream != self.stream {
            self.stream = sensorStream
            streamSub = nil
            frameRateSub = nil
            guard let stream = sensorStream.streamPublisher(for: metawear) else { return }
            populateMLPredictor(with: stream)
            reportFrameRate(of: stream)
        }

        predictionSubs = []
        self.predictor = predictor

        DispatchQueue.main.async {
            self.description = predictor.description
            self.supportedOutputs = predictor.possibleClassifications
        }

        reportPredictions()
    }

    public func onAppear() {
        guard let stream = stream.streamPublisher(for: metawear), !didSetup else { return }
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
}

private extension PredictUseCase {

    func populateMLPredictor(with stream: AnyPublisher<[Float],MWError>) {
        streamSub = stream
            .sink(receiveCompletion: { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                DispatchQueue.main.async { [weak self] in
                    self?.error = .init(error: error)
                }
            }, receiveValue: { [weak self] in self?.predictor?.add(datum: $0) })

        metawear?.connect()
    }

    func reportFrameRate(of stream: AnyPublisher<[Float],MWError>) {
        frameRateSub = stream
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

extension SIMD {
    var linearArray: [Self.Scalar] { self.indices.map { self[$0] } }
}
