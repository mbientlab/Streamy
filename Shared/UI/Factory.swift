import Foundation
import SwiftUI
import MetaWear
import MetaWearSync

/// Configure controllers with private app resources.
///
class UIFactory: ObservableObject {
    private unowned let root: Root
    init(root: Root) {
        self.root = root
    }
}

// MARK: - Routing utilities

extension UIFactory {

    func getKnownDevice(mac: MACAddress) -> MWKnownDevice? {
        root.syncedDevices.getDeviceAndMetadata(mac)
    }

    func getUnknownDevice(id: CBPeripheralIdentifier) -> MWNearbyUnknownDevice? {
        let (device, metadata) = root.syncedDevices.getDevice(byLocalCBUUID: id)
        guard let device = device
        // Unless the provided ID is incorrect,
        // the expectation is to always retrieve a MetaWear reference from CoreBluetooth
        else { return nil }
        return (device, metadata)
    }
}

// MARK: - Create pairs of Controllers and respective View Models

extension UIFactory {

    func makeDeviceListObservables()
    -> Observed<DevicesListViewModel<DeviceListUseCase>> {
        observe(.init(root.syncedDevices, root.scanner))
    }

    func makeBluetoothStateObservables()
    -> Observed<BluetoothStateViewModel<BluetoothUseCase>> {
        observe(.init(root.scanner))
    }

    func makeKnownDeviceObservables(for device: MWKnownDevice)
    ->  Observed<KnownDeviceCellViewModel<KnownDeviceUseCase>> {
        observe(.init(device, root.syncedDevices))
    }

    func makeUnknownDeviceObservables(for device: MWNearbyUnknownDevice, tasks: UnownedCancellableStore)
    -> Observed<UnknownDeviceCellViewModel<UnknownDeviceUseCase>> {
        observe(.init(nearby: device, sync: root.syncedDevices, tasks: tasks))
    }

    func makeNextStepsObservables(for device: MWKnownDevice)
    -> Observed<NextStepsViewModel<NextStepsUseCase>> {
        observe(.init(device))
    }

    func makeNewSessionObservables(for device: MWKnownDevice)
    -> Observed<NewSessionViewModel<NewSessionUseCase>> {
        observe(.init(device))
    }

    func makeDownloadObservables(for device: MWKnownDevice)
    -> Observed<DownloadViewModel<DownloadUseCase>> {
        let date = getLogSessionStartDate(for: device)
        return observe(.init(device, startDate: date))
    }

    private func getLogSessionStartDate(for device: MWKnownDevice) -> Date {
        .now // Fake in this demo app. Yours can persist this across sessions like _MetaBase_.
    }
}

// MARK: - View Model – Controller Mappers
//
// Decouples views from logic.
//
// Use of generics ensures SwiftUI views can observe any controller... if given a View Model that can translate its properties. That translation is achieved mostly via key paths.
//
// Similarly, the ``Views`` struct decouples other views from concrete implementations, so you can swap implementations in the routing view if you'd like to morph this sample app into your own.

extension UnknownDeviceCellViewModel: Observer where O == UnknownDeviceUseCase {
    init<O: UnknownDeviceUseCase>(_ controller: O) {
        self.name = \.name
        self.rssi = \.rssi
        self.connection = \.connection
        self.isCloudSynced = \.isCloudSynced
        self.rename = nil
        self.remember = controller.remember
        self.onAppear = controller.onAppear
    }
}

extension KnownDeviceCellViewModel: Observer where O == KnownDeviceUseCase {
    init<O: KnownDeviceUseCase>(_ controller: O) {
        self.name = \.name
        self.mac = \.metadata.mac
        self.rssi = \.rssi
        self.connection = \.connection
        self.isCloudSynced = \.isCloudSynced
        self.showRenameRecovery = \.showRenamePrompt
        self.rename = controller.rename
        self.connect = controller.connect
        self.disconnect = controller.disconnect
        self.identify = controller.identify
        self.forget = controller.forget
        self.reset = controller.reset
        self.onAppear = controller.onAppear
    }
}

extension DevicesListViewModel: Observer where O == DeviceListUseCase {
    init<O: DeviceListUseCase>(_ controller: O) {
        self.unknowns = \.unknownDevices
        self.knowns = \.knownDevices
        self.tasks = \.unknownIdentifierSubs
        self.onAppear = controller.onAppear
    }
}

extension BluetoothStateViewModel: Observer where O == BluetoothUseCase {
    init<O: BluetoothUseCase>(_ controller: O) {
        self.showError = \.showError
        self.isScanning = \.isScanning
        self.toggleScanning = controller.toggleScanning
        self.showSettings = controller.showBluetoothSettings
        self.onAppear = controller.onAppear
    }
}

extension NextStepsViewModel: Observer where O  == NextStepsUseCase {
    init<O: NextStepsUseCase>(_ controller: O) {
        self.title = \.deviceName
        self.ctaLabel = \.cta.displayName
        self.cta = \.cta
        self.enableCTA = \.state.isReady
        self.didTapCTA = controller.didTapCTA
        self.onAppear = controller.onAppear
    }
}

extension NewSessionViewModel: Observer where O == NewSessionUseCase {
    init<O: NewSessionUseCase>(_ controller: O) {
        self.title = \.deviceName
        self.ctaLabel = \.cta.displayName
        self.cta = \.cta
        self.menu = \.sensorChoices
        self.selection = \.sensors
        self.isWorking = \.state.isWorking
        self.enableCTA = \.state.isReady
        self.didTapCTA = controller.didTapCTA
        self.toggle = controller.toggleSensor
    }
}

extension DownloadViewModel: Observer where O == DownloadUseCase {
    init<O: DownloadUseCase>(_ controller: O) {
        self.title = \.deviceName
        self.ctaLabel = \.cta.displayName
        self.enableCTA = \.state.isReady
        self.state = \.state
        self.export = \.export
        self.didTapCTA = controller.didTapCTA
        self.onAppear = controller.onAppear
    }
}

// MARK: - Factory Sugar
//
// The factory's methods all instantiate a Controller object and a View Model that exposes that concrete Controller's properties to views.
//
// Since creating that tuple involves a few lines of repetitive code, this defines a tuple with two objects of dependent types. A private function creates that tuple with more terse call-site code.

typealias Observed<ViewModel: Observer> = (ViewModel.O, ViewModel)

fileprivate func observe<ViewModel: Observer>(_ controller: ViewModel.O)
-> Observed<ViewModel> {
    (controller, .init(controller))
}

protocol Observer {
    associatedtype O: ObservableObject
    init(_ controller: O)
}
