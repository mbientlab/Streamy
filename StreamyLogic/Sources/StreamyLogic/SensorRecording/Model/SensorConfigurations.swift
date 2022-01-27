import Foundation
import MetaWear

/// Setup preset options for activating an arbitrary selection of MetaWear sensors.
/// Could be used for logging or streaming commands.
///
internal struct SensorConfigurations {
    var accelerometer: MWAccelerometer? = nil
    var gyroscope:     MWGyroscope?     = nil
    var linearAcc:     MWSensorFusion.LinearAcceleration? = nil
    var quaternion:    MWSensorFusion.Quaternion? = nil
    var button:        MWMechanicalButton? = nil

    /// Input a valid selection of signals (some are mutually exclusive).
    ///
    init(selections: Set<MWNamedSignal>)  {
        if selections.contains(.mechanicalButton) {
            button = .init()
        }

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
