import Foundation
import MetaWear
import MetaWearSync
import Combine
import CoreBluetooth

/// Interacts with a device that the local machine has not seen before (or the user requested to "forget" earlier this session).
///
/// See `From Zero to Machine Learning -> Chapter 1 -> Connecting to MetaWears -> Section 2`.
///
public class UnknownDeviceUseCase: ObservableObject {

    public let name: String
    public let isCloudSynced: Bool
    @Published public private(set) var rssi: Int
    @Published public private(set) var connection: CBPeripheralState

    private weak var metawear:  MetaWear?
    private weak var sync:      MetaWearSyncStore?
    private weak var tasks:     UnownedCancellableStore?
    private      var rssiSub:   AnyCancellable? = nil

    public init(nearby: MWNearbyUnknownDevice,
         sync:   MetaWearSyncStore,
         tasks:  UnownedCancellableStore
    ) {
        self.metawear = nearby.metawear
        self.name = nearby.metadata?.name ?? nearby.metawear.name
        self.connection = nearby.metawear.connectionState
        self.isCloudSynced = nearby.metadata != nil
        self.rssi = nearby.metawear.rssi
        self.sync = sync
        self.tasks = tasks
    }

    public func onAppear() {
        rssiSub = metawear?.rssiPublisher
            .onMain()
            .sink { [weak self] in self?.rssi = $0 }
    }

    public func remember() {
        guard let id = metawear?.localBluetoothID, let sync = sync else { return }
        self.connection = .connecting
        SDKAction.rememberUnknownDevice(sync, id: id, host: tasks, subs: \.subs)
    }
}
