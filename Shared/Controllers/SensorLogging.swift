import SwiftUI
import MetaWear
import MetaWearSync
import Combine
import CoreBluetooth

/// Interacts with a known, local device.
///
/// See `From Zero to Machine Learning -> Chapter 2 -> Log Sensor Data`.
///
class SensorLoggingController: ObservableObject {

    let name: String

    // What sensors should be logged?
    @Published private(set) var selectedSensors: Set<MWNamedSignal> = []
    let availableSensors: [MWNamedSignal] = [.acceleration, .gyroscope]
    private var startDate: Date           = .init()
    private let accelerometerConfig       = MWAccelerometer(rate: .hz100, gravity: .g16)
    private let gyroscopeConfig           = MWGyroscope(rate: .hz100, range: .dps2000)

    // Is the device present and connected, ready to accept a command?
    @Published private(set) var state:      State = .unknown
    @Published private(set) var enableCTAs: Bool
    private var enableCTAsSub:              AnyCancellable? = nil

    // To trigger a SwiftUI export API
    @Published var showFolderExporter     = false
    @Published private(set) var exportable: Folder? = nil

    init(mac: MACAddress, sync: MetaWearSyncStore) {
        let (device, metadata) = sync.getDeviceAndMetadata(mac)!
        self.metawear = device!
        self.name = metadata.name
        self.enableCTAs = device?.connectionState == .connected
    }

    deinit { try? FileManager.default.removeItem(at: Self.tempFolder) }

    private unowned let metawear: MetaWear
    private var logSub: AnyCancellable? = nil
    private var downloadSub: AnyCancellable? = nil

    enum State: Equatable {
        case unknown
        case logging
        case downloading(Double)
        case downloaded
        case loggingError(String)
        case downloadError(String)
        case exportError(String)
    }
}

extension SensorLoggingController {

    func onAppear() {
        metawear.connect()

        enableCTAsSub = metawear.connectionStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.enableCTAs = $0 == .connected }
    }

    /// Some sensors cannot be logged at the same time.
    ///
    func toggleSensor(_ sensor: MWNamedSignal) -> Binding<Bool>  {
        Binding(
            get: { [weak self] in self?.selectedSensors.contains(sensor) == true },
            set: { [weak self] shouldUse in
                guard shouldUse else { self?.selectedSensors.remove(sensor); return }
                self?.selectedSensors.removeConflicts(for: sensor)
                self?.selectedSensors.insert(sensor)
            }
        )
    }

    /// Start logging and store a timestamp to synchronize dates in the CSV downloaded later.
    /// A timestamp is more useful when logging from multiple devices at once.
    ///
    func log() {
        guard selectedSensors.isEmpty == false else { return }

        logSub = metawear
            .publishWhenConnected()
            .first()
            .optionallyLog(selectedSensors.contains(.gyroscope) ? gyroscopeConfig : nil)
            .optionallyLog(selectedSensors.contains(.acceleration) ? accelerometerConfig : nil)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                self?.state = .loggingError(error.localizedDescription)
            } receiveValue: { [weak self] _ in
                self?.state = .logging
                self?.startDate = .init()
            }

        metawear.connect()
    }

    /// Download all logged data present on the device, from any type of sensor.
    /// After progress reports hit 1.0 (100%), an array of MWDataTable arrives.
    /// This table contains Stringly-typed timestamped data. Using `.stream` will
    /// return data in native Swift types.
    ///
    func download() {
        downloadSub = metawear
            .publishWhenConnected()
            .first()
            .downloadLogs(startDate: startDate)
            .handleEvents(receiveOutput: { [weak self] (_, percentComplete) in
                DispatchQueue.main.async { [weak self] in
                    self?.state = .downloading(percentComplete)
                }
            })
            .drop { $0.percentComplete < 1 }
            .sink { [weak self] completion in
                guard case let .failure(error) = completion else { return }
                DispatchQueue.main.async { [weak self] in
                    self?.state = .downloadError(error.localizedDescription)
                }
            } receiveValue: { [weak self] (dataTables, percentComplete) in
                self?.prepareExportAndUpdateUI(for: dataTables)
            }
    }

// MARK: - Export
//         This is just a quick and dirty export implementation for this demo app using SwiftUI's FileDocument API.
//         The only line of code worth paying attention to is:
//     ```
//     [MWDataTable].map { table in
//         (filename: table.source.name, csv: table.makeCSV())
//     }
//     ```

    func export() {
        if exportable != nil { showFolderExporter = true }
    }

    func reportExportError(_ error: Error) {
        state = .exportError(error.localizedDescription)
    }

}

private extension SensorLoggingController {

    func prepareExportAndUpdateUI(for dataTables: [MWDataTable]) {
        do {
            let exportableFolder = try makeCSVs(from: dataTables)
            DispatchQueue.main.async { [weak self] in
                self?.exportable = exportableFolder
                self?.state = .downloaded
            }
        } catch let error {
            DispatchQueue.main.async { [weak self] in
                self?.state = .exportError(error.localizedDescription)
            }
        }
    }

    func makeCSVs(from tables: [MWDataTable]) throws -> Folder {
        let folderName = [metawear.name, startDate.formatted(date: .abbreviated, time: .shortened)].joined(separator: " ")
        let files = tables.map { table -> (filename: String, csv: String) in
            let filename = [table.source.name, folderName].joined(separator: " ")
            return (filename, table.makeCSV())
        }

        let folderURL = try getTempDirectory(named: folderName)
        for file in files {
            let url = folderURL.appendingPathComponent(file.filename).appendingPathExtension(for: .commaSeparatedText)
            try file.csv.write(to: url, atomically: true, encoding: .utf8)
        }
        return try Folder(url: folderURL, name: folderName)
    }

    func getTempDirectory(named: String) throws -> URL {
        let url = Self.tempFolder.appendingPathComponent(named, isDirectory: true)
        try? FileManager.default.removeItem(at: url)
        try FileManager.default.createDirectory(atPath: url.path, withIntermediateDirectories: true, attributes: nil)
        return url
    }

    private static let tempFolder = FileManager.default.temporaryDirectory.appendingPathComponent("StreamyLogExport", isDirectory: true)
}
