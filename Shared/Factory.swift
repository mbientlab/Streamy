import SwiftUI
import MetaWear
import MetaWearSync
import StreamyLogic

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

    func makeDeviceListObservables() -> Observed<
        DeviceListUseCase,
        DevicesListViewModel<DeviceListUseCase>
    > {
        .observe(.init(root.syncedDevices, root.scanner))
    }

    func makeBluetoothStateObservables() -> Observed<
        BluetoothUseCase,
        BluetoothStateViewModel<BluetoothUseCase>
    > {
        .observe(.init(root.scanner))
    }

    func makeKnownDeviceObservables(for device: MWKnownDevice) ->  Observed<
        KnownDeviceUseCase,
        KnownDeviceCellViewModel<KnownDeviceUseCase>
    > {
        .observe(.init(device, root.syncedDevices))
    }

    func makeUnknownDeviceObservables(for device: MWNearbyUnknownDevice, tasks: UnownedCancellableStore) -> Observed<
        UnknownDeviceUseCase,
        UnknownDeviceCellViewModel<UnknownDeviceUseCase>
    > {
        .observe(.init(nearby: device, sync: root.syncedDevices, tasks: tasks))
    }

    func makeNextStepsObservables(for device: MWKnownDevice) -> Observed<
        NextStepsUseCase,
        NextStepsViewModel<NextStepsUseCase>
    > {
        .observe(.init(device))
    }

    func makeNewSessionObservables(for device: MWKnownDevice)
    -> Observed<
        NewSessionUseCase,
        NewSessionViewModel<NewSessionUseCase, LoggingBehavior>
    > {
        .observe(.init(device))
    }

    func makeNewSessionBehaviorsObservables(for device: MWKnownDevice)
    -> Observed<
        NewSessionBehaviorsUseCase,
        NewSessionViewModel<NewSessionBehaviorsUseCase, LoggingBehavior>
    > {
        .observe(.init(device))
    }

    func makeDownloadObservables(for device: MWKnownDevice)
    -> Observed<
        DownloadUseCase,
        DownloadViewModel<DownloadUseCase>
    > {
        let date = getLogSessionStartDate(for: device)
        return .observe(.init(device, startDate: date))
    }

    func makePredictionObservables(for device: MWKnownDevice)
    -> Observed<
        CoreMLSetupUseCase,
        ChooseModelVM<CoreMLSetupUseCase, SensorStreamForCoreML>
    > {
        .observe(.init(device, root.coreML))
    }

    private func getLogSessionStartDate(for device: MWKnownDevice) -> Date {
        .now // Fake in this demo app. Yours can persist this across sessions like _MetaBase_.
    }
}

// MARK: - View Model – UseCase/Controller Mapping

/// Streamy decouples views from logic, so you can modify it more freely.
///
/// Streamy's SwiftUI Views depend upon generic ObservableObjects. A view model provides access to information and methods, likely available on that generic ObservableObject.
///
/// The link between a concrete ObservableObject and a view model is mostly done via read or read/write KeyPaths, defined below in this file. The ``Observed`` struct is just sugar to pass the linked pair as one item and make the factory object's methods more structured.
///
/// Similarly, the ``Views`` struct decouples other SwiftUI Views from concrete view implementations. You can swap implementations using the ``Views`` "routing" views to modify this sample app bit-by-bit.
///
struct Observed<Object, VM> {
    let object: Object
    let vm: VM
}

extension Observed where
Object == UnknownDeviceUseCase,
VM == UnknownDeviceCellViewModel<UnknownDeviceUseCase> {

    static func observe(_ object: Object) -> Self {
        .init(object: object,
              vm: .init(
                name: \.name,
                rssi: \.rssi,
                connection: \.connection,
                isCloudSynced: \.isCloudSynced,
                rename: nil,
                remember: object.remember,
                onAppear: object.onAppear
              )
        )
    }
}

extension Observed where
Object == KnownDeviceUseCase,
VM == KnownDeviceCellViewModel<KnownDeviceUseCase> {

    static func observe(_ object: Object) -> Self {
        .init(object: object,
              vm: .init(
                name: \.name,
                mac: \.metadata.mac,
                rssi: \.rssi,
                connection: \.connection,
                isCloudSynced: \.isCloudSynced,
                showRenameRecovery: \.showRenamePrompt,
                rename: object.rename,
                connect: object.connect,
                disconnect: object.disconnect,
                identify: object.identify,
                forget: object.forget,
                reset: object.resetDeletingLogs,
                onAppear: object.onAppear
              )
        )
    }
}

extension Observed where
Object == DeviceListUseCase,
VM == DevicesListViewModel<DeviceListUseCase> {

    static func observe(_ object: Object) -> Self {
        .init(object: object,
              vm: .init(
                unknowns: \.unknownDevices,
                knowns: \.knownDevices,
                tasks: \.unknownIdentifierSubs,
                onAppear: object.onAppear,
                onDisappear: object.onDisappear
              )
        )
    }
}


extension Observed where
Object == BluetoothUseCase,
VM == BluetoothStateViewModel<BluetoothUseCase> {

    static func observe(_ object: Object) -> Self {
        .init(object: object,
              vm: .init(
                showError: \.showError,
                isScanning: \.isScanning,
                toggleScanning: object.toggleScanning,
                showSettings: object.showBluetoothSettings,
                onAppear: object.onAppear
              )
        )
    }
}

extension Observed where
Object == NextStepsUseCase,
VM == NextStepsViewModel<NextStepsUseCase> {

    static func observe(_ object: Object) -> Self {
        .init(object: object,
              vm: .init(
                title: \.deviceName,
                ctas: { object.ctas.sorted(using: KeyPathComparator(\.displayName)) },
                enableCTA: \.state.isReady,
                didTapCTA: object.didTapCTA,
                onAppear: object.onAppear
              )
        )
    }
}

extension Observed where
Object == NewSessionUseCase,
VM == NewSessionViewModel<NewSessionUseCase, LoggingBehavior> {

    static func observe(_ object: Object) -> Self {
        .init(object: object,
              vm: .init(
                title:  \.deviceName,
                ctaLabel: \.cta.displayName,
                cta: \.cta,
                menu: \.sensorChoices,
                selection: \.sensors,
                isWorking: \.state.isWorking,
                enableCTA: \.state.isReady,
                didTapCTA: object.didTapCTA,
                toggle: object.toggleSensor,
                behavior: nil,
                behaviorOptions: nil
              )
        )
    }
}

extension Observed where
Object == NewSessionBehaviorsUseCase,
VM == NewSessionViewModel<NewSessionBehaviorsUseCase, LoggingBehavior> {

    static func observe(_ object: Object) -> Self {
        .init(object: object,
              vm: .init(
                title:  \.deviceName,
                ctaLabel: \.cta.displayName,
                cta: \.cta,
                menu: \.sensorChoices,
                selection: \.sensors,
                isWorking: \.state.isWorking,
                enableCTA: \.state.isReady,
                didTapCTA: object.didTapCTA,
                toggle: object.toggleSensor,
                behavior: \.behavior,
                behaviorOptions: \.behaviorOptions
              )
        )
    }
}

extension Observed where
Object == DownloadUseCase,
VM == DownloadViewModel<DownloadUseCase> {
    static func observe(_ object: Object) -> Self {
        .init(object: object,
              vm: .init(
                title: \.deviceName,
                ctaLabel: \.cta.displayName,
                enableCTA: \.state.isReady,
                state: \.state,
                export: \.export,
                didTapCTA: object.didTapCTA,
                onAppear: object.onAppear,
                showSplitAlert: \.confirmSplitting,
                didChooseToSplit: object.didChooseToSplitCSVColumns(byButtonPresses:)
              )
        )
    }
}

extension Observed where
Object == CoreMLSetupUseCase,
VM == ChooseModelVM<CoreMLSetupUseCase, SensorStreamForCoreML> {

    static func observe(_ object: Object) -> Self {
        .init(object: object,
              vm: .init(
                sensorChoice: \.sensor,
                modelChoice: \.model,
                modelChoices: \.modelChoices,
                sensorChoices: \.sensorChoices,
                predictor: \.predictor,
                isLoading: \.isLoading,
                error: \.error,
                onAppear: object.onAppear,
                loadModel: object.startModel
              )
        )
    }
}

extension Observed where
Object == PredictUseCase,
VM == PredictViewModel<PredictUseCase> {

    static func observe(_ object: Object) -> Self {
        .init(object: object,
              vm: .init(
                instruction: \.description,
                outputs: \.supportedOutputs.sortedByLetter,
                prediction: \.prediction,
                predictions: \.probabilities,
                windowWidth: \.windowWidth,
                frameRate: \.frameRate,
                predictionRate: \.predictionRate,
                error: \.error,
                onAppear: object.onAppear
              )
        )
    }
}
