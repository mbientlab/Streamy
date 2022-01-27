import Foundation
import MetaWear

/// Options for how the MetaWear will organize logging data
///
public enum LoggingBehavior: String, CaseIterable, IdentifiableByRawValue {
    /// Continuously logs upon command until a stop or download command
    case startImmediatelyNoSplits
    /// Powers and configures sensors, but will ignore data until button press events
    case startLazilyPausePlayLoggersOnButtonDownUp
}
