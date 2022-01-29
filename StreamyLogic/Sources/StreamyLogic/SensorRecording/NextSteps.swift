import SwiftUI
import MetaWear
import MetaWearSync
import Combine

/// Determines whether the device has logged data available for downloading and points to the next logical use case.
/// Could be extended to retrieve a list of sensor recordings from this device, pointing to an export use case for each session.
///
public class NextStepsUseCase: ObservableObject {

    @Published public private(set) var ctas:  Set<UseCaseCTA>  = [.connect]
    @Published public private(set) var state: UseCaseState     = .ready
    public let deviceName:                    String

    private weak var metawear:         MetaWear?       = nil
    private var      getCTASub:        AnyCancellable? = nil

    public init(_ knownDevice: MWKnownDevice) {
        self.metawear = knownDevice.mw
        self.deviceName = knownDevice.meta.name
    }
}

public extension NextStepsUseCase {

    /// UI should navigate on kickoff CTAs, unless recovering from an error message
    func didTapCTA() {
        getCTAState()
    }

    func onAppear() {
        getCTAState()
    }
}

private extension NextStepsUseCase {

    func getCTAState() {
        guard let metawear = metawear else {
            state = .error(MWError.operationFailed("MetaWear not found."))
            return
        }
        
        getCTASub = SDKAction
            .isLogging(metawear)
            .sink(
                receiveCompletion: { [weak self] in self?.handleError($0) },
                receiveValue:      { [weak self] in self?.updateCTAState(isLogging: $0) }
            )

        metawear.connect()
    }

    func handleError(_ completion: Subscribers.Completion<MWError>) {
        guard case .failure = completion else { return }
        ctas = [.connect]
        state = .ready
    }

    func updateCTAState(isLogging: Bool) {
        ctas = isLogging ? [.download] : [.configure, .predict]
        state = .ready
    }
}
