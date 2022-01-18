import SwiftUI
import CoreBluetooth

struct KnownDeviceCellViewModel<O: ObservableObject>: DeviceCellParentVM {
    let name:               KeyPath<O, String>
    let mac:                KeyPath<O, String>
    let rssi:               KeyPath<O, Int>
    let connection:         KeyPath<O, CBPeripheralState>
    let isCloudSynced:      KeyPath<O, Bool>
    let showRenameRecovery: ReferenceWritableKeyPath<O, Bool>
    let rename:             ((String) -> Void)?
    let connect:            () -> Void
    let disconnect:         () -> Void
    let identify:           () -> Void
    let forget:             () -> Void
    let reset:              () -> Void
    let onAppear:           () -> Void
}

struct KnownDeviceCell<Object: ObservableObject>: View {

    init(_ observable: (object: Object, vm: KnownDeviceCellViewModel<Object>)) {
        _state = .init(wrappedValue: observable.object)
        self.vm = observable.vm
    }

    @StateObject private var state: Object
    private let vm: KnownDeviceCellViewModel<Object>


    var body: some View {
        navigableCell
            .onAppear(perform: vm.onAppear)
            .contextMenu { KnownDeviceContextMenu(state: state, vm: vm) }
            .alert("Invalid MetaWear Name",
                   isPresented: $state[dynamicMember: vm.showRenameRecovery],
                   actions: { Button("Ok") { } },
                   message: { Text("MetaWear names can be up to 26 alphanumeric characters, including _, -, and spaces.") })
    }

    private var navigableCell: some View {
        NavigationLink(
            destination: {
                Views.NextSteps()
                    .environment(\.routedDevice, state[keyPath: vm.mac])
            }, label: { DeviceListCell(state, vm) }
        )
    }
}

struct KnownDeviceContextMenu<Object: ObservableObject>: View {

    @ObservedObject var state: Object
    let vm: KnownDeviceCellViewModel<Object>

    private var canConnect: Bool { state[keyPath: vm.connection] < .connecting }

    var body: some View {
        Text(state[keyPath: vm.mac])
        Divider()
        Button(canConnect ? "Connect" : "Disconnect", action: canConnect ? vm.connect : vm.disconnect)
        Button("Reset Activities & Data") { vm.reset() }
        Button("Flash LEDs") { vm.identify() }
        Divider()
        Button("Forget") { vm.forget() }
    }
}
