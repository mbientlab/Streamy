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
    var pressure:      MWBarometer.MWPressure? = nil

    /// Input a valid selection of signals (some are mutually exclusive).
    ///
    init(selections: Set<MWNamedSignal>)  {
        if selections.contains(.mechanicalButton) {
            button = .init()
        }

        if selections.contains(.pressure) {
            pressure = MWBarometer.MWPressure(standby: .ms0_5, iir: .off, oversampling: .standard)
        }

        if selections.contains(.linearAcceleration) {
            linearAcc  = .init(mode: .ndof)
            return
        } else if selections.contains(.quaternion) {
            quaternion = .init(mode: .ndof)
            return
        }

        if selections.contains(.acceleration) {
            accelerometer = .init(rate: .hz50, gravity: .g16)
        }
        if selections.contains(.gyroscope) {
            gyroscope = .init(rate: .hz50, range: .dps2000)
        }
    }
}
