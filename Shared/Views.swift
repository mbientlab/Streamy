import SwiftUI
import MetaWear
import MetaWearSync
import StreamyLogic

/// Streamy allows views to call upon an abstract "other view" via this Views struct, decoupling views from each other's concrete implementation.
///
/// Views inside ``Views`` act as mini-routers:
/// - If you wish to swap UI components (e.g., different macOS views)
/// - If requirements to construct a view fail, it can fallback to other views such as error UI.
///
struct Views {
    private init(){}
    struct DeviceList { private init(){} }
}

extension Views {

    struct NextSteps: View {
        @Environment(\.routedDevice) var routedDevice
        @EnvironmentObject private var factory: UIFactory

        var body: some View {
            if let mac = routedDevice,
               let device = factory.getKnownDevice(mac: mac) {
                let observables = factory.makeNextStepsObservables(for: device)
#if os(macOS)
                /// See ``ThirdPaneRouter`` implementation for explanation. ``NextStepsView_MiddleColumnNavStyle`` is identical except for removing the CTA after navigation.
                ThirdPaneRouter(middle: NextStepsView_MiddleColumnNavStyle(observables))
#elseif os(iOS)
                if UIDevice.current.userInterfaceIdiom == .pad {
                    ThirdPaneRouter(middle: NextStepsView_MiddleColumnNavStyle(observables))
                } else {
                    NextStepsView_StackNavStyle(observables)
                }
#endif
            } else { WhoopsView(message: Views.failNoDevice) }
        }
    }

    struct NewSession: View {
        @Environment(\.routedDevice) var routedDevice
        @EnvironmentObject private var factory: UIFactory

        var body: some View {
            if let mac = routedDevice,
               let device = factory.getKnownDevice(mac: mac) {
                NewSessionView(factory.makeNewSessionObservables(for: device))
            } else { WhoopsView(message: Views.failNoDevice) }
        }
    }

    struct Download: View {
        @Environment(\.routedDevice) var routedDevice
        @EnvironmentObject private var factory: UIFactory

        var body: some View {
            if let mac = routedDevice,
               let device = factory.getKnownDevice(mac: mac) {
                DownloadView(factory.makeDownloadObservables(for: device))
            } else { WhoopsView(message: Views.failNoDevice) }
        }
    }

    struct BluetoothToggle: View {
        @EnvironmentObject private var factory: UIFactory
        var body: some View {
            BluetoothStateToggleButton(factory.makeBluetoothStateObservables())
        }
    }

    static let failNoDevice = "Missing routed device Environment Key."
}

extension Views.DeviceList {

    struct SidebarList: View {
        @EnvironmentObject private var factory: UIFactory

        var body: some View {
            DeviceListSidebar(factory.makeDeviceListObservables())
        }
    }

    struct KnownCell: View {
        @EnvironmentObject private var factory: UIFactory

        let mac: MACAddress

        var body: some View {
            if let device = factory.getKnownDevice(mac: mac) {
                KnownDeviceCell(factory.makeKnownDeviceObservables(for: device))
                    .environment(\.routedDevice, mac)
            } else { WhoopsRow(message: "\(mac) missing") }
        }
    }

    struct UnknownCell: View {
        @EnvironmentObject private var factory: UIFactory

        let id: CBPeripheralIdentifier
        let tasks: UnownedCancellableStore

        var body: some View {
            if let device = factory.getUnknownDevice(id: id) {
                UnknownDeviceCell(factory.makeUnknownDeviceObservables(for: device, tasks: tasks))
                    .environment(\.routedNearbyDevice, id)
            } else { WhoopsRow(message: "\(id) missing") }
        }
    }
}

// MARK: - Define Target MetaWear Device in the Environment
//
// Child components, such as a connection indicator, can find information about what to monitor from these keys.

extension EnvironmentValues {

    var routedNearbyDevice: CBPeripheralIdentifier? {
        get { return self[FocusedNearbyDevice.self] }
        set { self[FocusedNearbyDevice.self] = newValue }
    }

    var routedDevice: MACAddress? {
        get { return self[FocusedMACAddressEVK.self] }
        set { self[FocusedMACAddressEVK.self] = newValue }
    }

}

fileprivate struct FocusedMACAddressEVK: EnvironmentKey {
    static let defaultValue: MACAddress? = nil
}

fileprivate struct FocusedNearbyDevice: EnvironmentKey {
    static let defaultValue: CBPeripheralIdentifier? = nil
}
