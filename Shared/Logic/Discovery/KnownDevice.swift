import Foundation
import MetaWear
import MetaWearSync
import Combine
import CoreBluetooth

/// Interacts with a device that may or may not be known to the local machine, but has at least been seen by a user's other machines.
///
/// See `From Zero to Machine Learning -> Chapter 1 -> Connecting to MetaWears -> Section 3`.
///
class KnownDeviceUseCase: ObservableObject {

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
    private var connectionSub: AnyCancellable? = nil
    private var identitySub:   AnyCancellable? = nil
    private var flashLEDSub:   AnyCancellable? = nil
    private var resetSub:      AnyCancellable? = nil
    private var rssiSub:       AnyCancellable? = nil

    init(_ device: MWKnownDevice, _ sync: MetaWearSyncStore) {
        self.sync = sync
        (self.metawear, self.metadata) = device
        self.rssi = self.metawear?.rssi ?? -100
        self.connection = self.metawear?.connectionState ?? .disconnected
    }
}

extension KnownDeviceUseCase {

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

    func resetDeletingLogs() {
        guard let metawear = metawear else { return }
        resetSub = SDKAction
            .resetDeletingLogs(metawear)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
        metawear.connect()
    }

    func identify() {
        guard let metawear = metawear else { return }
        flashLEDSub = SDKAction
            .identify(metawear, pattern: .nine)
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
        metawear.connect()
    }
}

private extension KnownDeviceUseCase {

    func trackRSSI() {
        rssiSub = metawear?.rssiPublisher
            .onMain()
            .sink { [weak self] in self?.rssi = $0 }
    }

    func trackConnection() {
        connectionSub = metawear?.connectionStatePublisher
            .onMain()
            .sink { [weak self] in self?.connection = $0 }
    }

    func trackIdentity() {
        identitySub = sync?.publisher(for: metadata.mac)
            .onMain()
            .sink { [weak self] deviceReference, metadata in
                let justFoundMetaWear = self?.metawear == nil && deviceReference != nil
                self?.metawear = deviceReference
                self?.metadata = metadata

                if justFoundMetaWear {
                    self?.trackRSSI()
                    self?.trackConnection()
                }
            }
    }
}
