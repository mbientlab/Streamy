import Foundation
import MetaWear
import MetaWearSync
import Combine

/// Interacts with a device that the local machine has not seen before (or the user just requested to "forget").
///
/// See `From Zero to Machine Learning -> Chapter 1 -> Connecting to MetaWears -> Section 2`.
///
class UnknownDeviceController: ObservableObject {

    let name: String
    let isCloudSynced: Bool
    @Published private(set) var rssi: Int
    @Published private(set) var isConnecting = false

    private weak var metawear:  MetaWear?
    private weak var sync:      MetaWearSyncStore?
    private weak var parent:    DeviceListController?
    private      var rssiSub:   AnyCancellable? = nil

    init(id: CBPeripheralIdentifier,
         sync: MetaWearSyncStore,
         parent: DeviceListController) {
        let (device, metadata) = sync.getDevice(byLocalCBUUID: id)
        self.metawear = device
        self.name = metadata?.name ?? device!.name
        self.isCloudSynced = metadata != nil
        self.rssi = metawear!.rssi
        self.sync = sync
        self.parent = parent
    }

    func onAppear() {
        rssiSub = metawear?.rssiPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.rssi = $0 }
    }

    func remember() {
        guard let id = metawear?.localBluetoothID else { return }
        isConnecting = true

        sync?.connectAndRemember(unknown: id, didAdd: { [weak self] (device, _) in
            guard let parent = self?.parent else { return }
            device?.publishIfConnected()
                .command(.ledFlash(.Presets.one.pattern))
                .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                .store(in: &parent.childDidAddDeviceSubs)
        })
    }
}
