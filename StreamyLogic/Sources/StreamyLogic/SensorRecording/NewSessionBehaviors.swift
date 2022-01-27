import Foundation
import Combine
import MetaWearSync

/// Extends the NewSession use case with a customizable logging
/// behavior (that in this case helps to split log CSV files by
/// using the MetaWear's button to mark trial runs).
///
/// Note: This type of ObservableObject subclassing only works in
/// macOS 11.3 and iOS 14.5 (#71816443). Before then, manual
/// republishing is needed.
///
public class NewSessionBehaviorsUseCase: NewSessionUseCase {

    @Published public var behavior: LoggingBehavior   = .startLazilyPausePlayLoggersOnButtonDownUp
    public let behaviorOptions:     [LoggingBehavior] = LoggingBehavior.allCases
    private var republish:          AnyCancellable? = nil

    public override init(_ knownDevice: MWKnownDevice) {
        super.init(knownDevice)
        overrideSDKAction()
    }
}

private extension NewSessionBehaviorsUseCase {

    func overrideSDKAction() {
        self.action = { [weak self] device, sensors in
            SDKAction.log(
                withBehavior: self?.behavior,
                device,
                SensorConfigurations(selections: sensors)
            )
        }
    }
}
