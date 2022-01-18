import Foundation
import MetaWear
import MetaWearSync

/// Example wiring of key value containers needed by MetaWear's
///
/// See `From Zero to Machine Learning -> Chapter 1 -> Adding MetaWear to a Project`.
///
class Root: ObservableObject {

    /// Tracks found and nearby MetaWears across iOS/macOS using local and iCloud UserDefaults
    let syncedDevices: MetaWearSyncStore
    /// Finds nearby MetaWears using CoreBluetooth
    let scanner: MetaWearScanner

    private let localDefaults: UserDefaults
    private let cloudDefaults: NSUbiquitousKeyValueStore
    private let devicesLoader:  MWLoader<MWKnownDevicesLoadable>

    init() {
        self.localDefaults = .standard
        self.cloudDefaults = .default
//        You could also change the UserDefaults container the SDK uses.
//        UserDefaults.MetaWear.suite = localDefaults
        self.scanner       = MetaWearScanner.sharedRestore
        self.devicesLoader = MetaWeariCloudSyncLoader(localDefaults, cloudDefaults)
        self.syncedDevices = MetaWearSyncStore(scanner: scanner, loader: devicesLoader)
    }

    /// Loads devices and MetaWear.Metadata from persistence into memory.
    func start() {
        do {
            try syncedDevices.load()
            _ = cloudDefaults.synchronize()

        } catch { NSLog("Load failure: \(error.localizedDescription)") }
    }
}
