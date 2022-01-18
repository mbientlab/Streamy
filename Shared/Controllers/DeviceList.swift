import Foundation
import MetaWear
import MetaWearSync
import Combine

/// Populates a list of devices that a user has never connected to locally (unknownDevices) and devices that this local machine has used before or other machines have seen before (knownDevices).
///
/// See `From Zero to Machine Learning -> Chapter 1 -> Connecting to MetaWears -> Section 1`.
///
class DeviceListController: ObservableObject {

    @Published private(set) var unknownDevices: [CBPeripheralIdentifier] = []
    @Published private(set) var knownDevices:   [MACAddress] = []

    private weak var sync:     MetaWearSyncStore?
    private weak var scanner:  MetaWearScanner?
    private var unknownSub:    AnyCancellable?     = nil
    private var knownSub:      AnyCancellable?     = nil
    var childDidAddDeviceSubs: Set<AnyCancellable> = []

    init(_ sync: MetaWearSyncStore, _ scanner: MetaWearScanner) {
        self.sync = sync
        self.scanner = scanner
    }
}

extension DeviceListController {

    func onAppear() {
        scanner?.startScan(higherPerformanceMode: true)

        unknownSub = sync?.unknownDevices
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.unknownDevices = $0.sorted() }

        knownSub = sync?.knownDevices
            .receive(on: DispatchQueue.main)
            .sink { [weak self] metadata in
                self?.knownDevices = metadata
                    .sorted(using: KeyPathComparator(\.name))
                    .map(\.mac)
            }
    }

    func onDisappear() {
        scanner?.stopScan()
    }
}
