import Foundation
import MetaWear
import MetaWearSync
import Combine
import CoreBluetooth

/// Interacts with a device that may or may not be known to the local machine, but has at least been seen by a user's other machines.
///
/// See `From Zero to Machine Learning -> Chapter 1 -> Connecting to MetaWears -> Section 3`.
///
class KnownDeviceController: ObservableObject {

    var name: String { metadata.name }

    /// If this host machine never encountered this
    /// MetaWear before, CoreBluetooth won't provide a
    /// peripheral reference, but the MetaWearSyncStore
    /// will have metadata about this device.
    var isCloudSynced: Bool { metawear == nil }

    @Published private(set) var metadata:   MetaWearMetadata
    @Published private(set) var rssi:       Int
    @Published private(set) var connection: CBPeripheralState
    @Published var showRenamePrompt:        Bool = false

    private weak var metawear: MetaWear?
    private weak var sync:     MetaWearSyncStore?
    private var identitySub:   AnyCancellable? = nil
    private var identifySub:   AnyCancellable? = nil
    private var rssiSub:       AnyCancellable? = nil
    private var connectionSub: AnyCancellable? = nil
    private var resetSub:      AnyCancellable? = nil

    init(knownDevice: MACAddress, sync: MetaWearSyncStore) {
        self.sync = sync
        (self.metawear, self.metadata) = sync.getDeviceAndMetadata(knownDevice)!
        self.rssi = self.metawear?.rssi ?? -100
        self.connection = self.metawear?.connectionState ?? .disconnected
    }

    func onAppear() {
        trackIdentity()
        trackConnection()
        trackRSSI()
    }

    func connect() {
        metawear?.connect()
    }

    func disconnect() {
        metawear?.disconnect()
    }

    func forget() {
        sync?.forget(globally: metadata)
    }

    func rename(_ newName: String) {
        do { try sync?.rename(known: metadata, to: newName) }
        catch { showRenamePrompt = true }
    }

    func reset() {
        resetSub = metawear?
            .publishWhenConnected()
            .first()
            .command(.resetActivities)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })

        metawear?.connect()
    }

    func identify() {
        identifySub = metawear?.publishWhenConnected()
            .first()
            .command(.ledFlash(.Presets.one.pattern))
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
        if metawear?.connectionState ?? .disconnected < .connecting { metawear?.connect() }
    }
}

private extension KnownDeviceController {

    func trackRSSI() {
        rssiSub = metawear?.rssiPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.rssi = $0 }
    }

    func trackConnection() {
        connectionSub = metawear?.connectionStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.connection = $0 }
    }

    func trackIdentity() {
        identitySub = sync?.publisher(for: metadata.mac)
            .print()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] metawear, metadata in
                let metaWearReferenceNowAvailable = self?.metawear == nil && metawear != nil
                self?.metawear = metawear
                self?.metadata = metadata

                if metaWearReferenceNowAvailable {
                    self?.trackRSSI()
                    self?.trackConnection()
                }
            }
    }
}
