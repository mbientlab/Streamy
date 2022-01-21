import Foundation
import MetaWear
import MetaWearSync

/// Example of wiring up the MetaWear SDK to use specific key value containers for persisting known devices locally and via iCloud.
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
        
//        You can change the UserDefaults container that SDK uses.
//        UserDefaults.MetaWear.suite = localDefaults

        self.scanner       = MetaWearScanner.sharedRestore
        self.devicesLoader = MetaWeariCloudSyncLoader(localDefaults, cloudDefaults)
        self.syncedDevices = MetaWearSyncStore(scanner: scanner, loader: devicesLoader)
    }

    /// Loads MetaWearMetadata (i.e., identities of known devices across a user's machines) into memory from persistent stores. Be sure to ask the MetaWearScanner to start scanning. This populates the actual peripherals for those MetaWears into this app session.
    func start() {
        do {
            try syncedDevices.load()
            _ = cloudDefaults.synchronize()

        } catch { NSLog("Load failure: \(error.localizedDescription)") }

        // For debugging, all MetaWears' Bluetooth communications can be printed to the console. Individual MetaWear instances can be logged by setting the `logDelgate`.
        // MWConsoleLogger.shared.activateConsoleLoggingOnAllMetaWears = true
    }
}
