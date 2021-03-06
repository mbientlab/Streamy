import Foundation
import MetaWear
import MetaWearSync
import Combine

/// Populates a list of devices that a user has never connected to locally (unknownDevices) and devices that this local machine has used before or other machines have seen before (knownDevices).
///
/// See `From Zero to Machine Learning -> Chapter 1 -> Connecting to MetaWears -> Section 1`.
///
public class DeviceListUseCase: ObservableObject {

    @Published public private(set) var unknownDevices: [CBPeripheralIdentifier] = []
    @Published public private(set) var knownDevices:   [MACAddress] = []

    private weak var sync:     MetaWearSyncStore?
    private weak var scanner:  MetaWearScanner?
    private var unknownSub:    AnyCancellable?     = nil
    private var knownSub:      AnyCancellable?     = nil
    public let unknownIdentifierSubs: UnownedCancellableStore = .init()

    public init(_ sync: MetaWearSyncStore, _ scanner: MetaWearScanner) {
        self.sync = sync
        self.scanner = scanner
    }
}

public extension DeviceListUseCase {

    func onAppear() {
        scanner?.startScan(higherPerformanceMode: true)

        guard let sync = sync else { return }
        unknownSub = SDKAction.streamUnknownDeviceIDs(sync)
            .sink { [weak self] in self?.unknownDevices = $0 }

        knownSub = SDKAction.streamKnownDeviceIDs(sync)
            .sink { [weak self] in self?.knownDevices = $0 }
    }

    func onDisappear() {
        scanner?.stopScan()
    }
}
