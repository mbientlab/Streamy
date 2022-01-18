import SwiftUI
import MetaWear
import MetaWearSync
import Combine
import CoreBluetooth

/// Starts a new logging session with a customizable sensor configuration.
///
public class NewSessionUseCase: ObservableObject {

    @Published public private(set) var sensors:  Set<MWNamedSignal> = []
    public let sensorChoices:                    [MWNamedSignal] = [
        .acceleration, .gyroscope, .linearAcceleration, .quaternion
    ]
    public private(set) var startDate:           Date

    @Published public private(set) var cta:      UseCaseCTA      = .log
    @Published public private(set) var state:    UseCaseState    = .notReady
    public let deviceName:                       String

    private weak var metawear:            MetaWear?       = nil
    private var actionSub:                AnyCancellable? = nil

    public init(_ knownDevice: MWKnownDevice) {
        self.startDate = .init()
        self.metawear = knownDevice.mw
        self.deviceName = knownDevice.meta.name
    }
}

public extension NewSessionUseCase {

    /// Start a logging session.
    ///
    func didTapCTA() {
        guard cta == .log,
              sensors.hasElements,
              let metawear = metawear
        else { return }

        state = .workingIndefinite

        actionSub = SDKAction
            .log(metawear, SensorConfigurations(selections: sensors))
            .sink(
                receiveCompletion: { [weak self] in displayError(from: $0, on: self, \.state) },
                receiveValue:      { [weak self] in self?.enableDownloading() }
            )

        metawear.connect()
    }

    /// Cache a timestamp to align data in a subsequent download.
    /// Streamy keeps this in memory. Your app should persist this so the user can close the app.
    ///
    private func enableDownloading() {
        startDate = .init()
        cta   = .download
        state = .ready
    }

    /// Some MetaWear logging options try to use the same sensors at the same time. Thus, their use is mutually exclusive.
    /// Specifically, when fusing sensors together to log quaternion, linear acceleration, gravity, or Euler angles,
    /// the accelerometer, gyroscope, and magnetometer will be occupied and cannot provide a second data stream.
    ///
    func toggleSensor(_ sensor: MWNamedSignal)  {
        guard sensors.contains(sensor) else {
            sensors.removeConflicts(for: sensor)
            sensors.insert(sensor)
            if state == .notReady { state = .ready }
            return
        }
        sensors.remove(sensor)
        if sensors.isEmpty { state = .notReady }
    }
}

/// Setup preset options for activating an arbitrary selection of MetaWear sensors.
/// Could be used for logging or streaming commands.
///
internal struct SensorConfigurations {
    var accelerometer: MWAccelerometer? = nil
    var gyroscope:     MWGyroscope?     = nil
    var linearAcc:     MWSensorFusion.LinearAcceleration? = nil
    var quaternion:    MWSensorFusion.Quaternion? = nil

    /// Input a valid selection of signals (some are mutually exclusive).
    ///
    init(selections: Set<MWNamedSignal>)  {
        if selections.contains(.linearAcceleration) {
            linearAcc  = .init(mode: .imuplus)
            return
        } else if selections.contains(.quaternion) {
            quaternion = .init(mode: .imuplus)
            return
        }

        if selections.contains(.acceleration) {
            accelerometer = .init(rate: .hz100, gravity: .g16)
        }
        if selections.contains(.gyroscope) {
            gyroscope = .init(rate: .hz100, range: .dps2000)
        }
    }
}
