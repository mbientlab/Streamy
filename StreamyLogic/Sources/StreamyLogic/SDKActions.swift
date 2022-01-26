import Foundation
import MetaWear
import MetaWearCpp
import MetaWearSync
import Combine
import CoreBluetooth

/// Bank of SDK commands.
/// Call `MetaWear.connect()` to ensure connection, as most methods fire on "publishWhenConnected().first()".
///
internal struct SDKAction { private init() {} }

// MARK: - Obtaining MetaWear References

extension SDKAction {

    /// Gets an updating list of nearby devices that have not been connected before or that the user asked to "forget"
    ///
    static func streamUnknownDeviceIDs(_ sync: MetaWearSyncStore) -> AnyPublisher<[CBPeripheralIdentifier],Never> {
        sync.unknownDevices
            .map { $0.sorted() }
            .onMain()
    }

    /// Gets an updating list of known devices that may or may not be nearby, as some may be cloud synced but never before connected by this host machine
    ///
    static func streamKnownDeviceIDs(_ sync: MetaWearSyncStore) -> AnyPublisher<[MACAddress],Never> {
        sync.knownDevices
            .map { metadata in
                metadata
                    .sorted(using: KeyPathComparator(\.name))
                    .map(\.mac)
            }
            .onMain()
    }
}

// MARK: - Control MetaWears

extension SDKAction {

    /// Connects to a locally never-used-before MetaWear. Upon successful connection, it flashes the MetaWear's LED to help with identification. Metadata about the device is stored in iCloud.
    ///
    /// Since this may be called in a cell that will disappear during the LED flashing command, which will terminate that LED command pipeline, it asks for a parent object whose lifetime will keep that LED flash command going.
    ///
    static func rememberUnknownDevice<Host: AnyObject>(
        _ sync: MetaWearSyncStore,
        id: CBPeripheralIdentifier,
        host: Host?,
        subs: ReferenceWritableKeyPath<Host,Set<AnyCancellable>>
    ) {
        let flashAfterConnection: (MWKnownDevice) -> Void = { [weak host] device in
            guard let host = host, let metawear = device.mw else { return }
            SDKAction.identify(metawear, color: .blue)
                .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                .store(in: &host[keyPath: subs])
        }

        sync.connectAndRemember(unknown: id, didAdd: flashAfterConnection)
    }

    /// Flashes the MetaWear's LED to help with identification. Does nothing if not connected (i.e., call `.connect()`).
    ///
    static func identify(_ metawear: MetaWear, color: MWLED.MBLColor) -> AnyPublisher<(),MWError> {
        metawear
            .publishWhenConnected()
            .first()
            .command(.led(color, .pulse(repetitions: 2)))
            .voidOnMain()
    }

    /// Checks the size of logged data on the MetaWear flash storage, reporting true if data is present.
    ///
    static func isLogging(_ metawear: MetaWear) -> AnyPublisher<Bool, MWError> {
        metawear.publishWhenConnected()
            .first()
            .read(.logLength)
            .map { $0.value > 0 }
            .onMain()
    }

    /// Resets the MetaWear and removes logged data, but retains settings. Does nothing if not connected (i.e., call `.connect()`).
    ///
    static func resetDeletingLogs(_ metawear: MetaWear) -> AnyPublisher<(),MWError> {
        metawear
            .publishWhenConnected()
            .first()
            .command(.deleteLoggedData)
            .command(.resetActivities)
            .voidOnMain()
    }

    /// Logs whatever sensor configuration(s) are passed in. Does nothing if not connected (i.e., call `.connect()`).
    ///
    static func log(_ metawear: MetaWear, _ configs: SensorConfigurations) -> AnyPublisher<(), MWError> {
        metawear
            .publishWhenConnected()
            .first()
            .optionallyLog(configs.accelerometer)
            .optionallyLog(configs.gyroscope)
            .optionallyLog(configs.linearAcc)
            .optionallyLog(configs.quaternion)
            .voidOnMain()
    }

    /// Downloads all logs on a device from any type of sensor.
    /// Progress estimates are sent on the main queue, but this returns on a background queue.
    /// Returns a string-encoded data in an array of MWDataTable, one per sensor type.
    /// (Streaming returns Swift native data types.)
    ///
    static func downloadLogs(from metawear: MetaWear,
                             startDate: Date,
                             progressEstimate: @escaping (Double) -> Void
    ) -> AnyPublisher<[MWDataTable], MWError> {

        metawear
            .publishWhenConnected()
            .first()
            .downloadLogs(startDate: startDate)
            .handleEvents(receiveOutput: { (_, percentComplete) in
                DispatchQueue.main.async {
                    progressEstimate(percentComplete)
                }
            })
            .drop { $0.percentComplete < 1 }
            .map(\.data)
            .receive(on: DispatchQueue.global())
            .eraseToAnyPublisher()
    }

    /// Changes downloaded data into CSV format.
    ///
    static func convertToCSVs(_ dataTables: [MWDataTable], filenamePrefix: String) -> [CSVFile] {
        dataTables.map { table -> (String, Data) in
            let filename = [table.source.name, filenamePrefix].joined(separator: " ")
            let csv = table.makeCSV(delimiter: ",").data(using: .utf8)!
            return (filename, csv)
        }
    }
}

public typealias CSVFile = (filename: String, csv: Data)

// MARK: - Error Handling Sugar

/// Updates state on an error with fewer lines at the call site.
///
public func displayError<Object: AnyObject>(
    from completion: Subscribers.Completion<MWError>,
    on object: Object?,
    _ statePath: ReferenceWritableKeyPath<Object,UseCaseState>
) {
    guard case let .failure(error) = completion else { return }
    DispatchQueue.main.async { [weak object] in
        object?[keyPath: statePath] = .error(error)
    }
}
