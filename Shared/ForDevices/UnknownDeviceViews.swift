import SwiftUI
import CoreBluetooth

struct UnknownDeviceCellViewModel<O: ObservableObject>: DeviceCellParentVM {
    let name:          KeyPath<O, String>
    let rssi:          KeyPath<O, Int>
    let connection:    KeyPath<O, CBPeripheralState>
    let isCloudSynced: KeyPath<O, Bool>
    let rename:        ((String) -> Void)?
    let remember:      () -> Void
    let onAppear:      () -> Void
}

struct UnknownDeviceCell<Object: ObservableObject>: View {

    init(_ observable: Observed<Object, UnknownDeviceCellViewModel<Object>>) {
        _state = .init(wrappedValue: observable.object)
        self.vm = observable.vm
    }

    @StateObject private var state: Object
    private let vm: UnknownDeviceCellViewModel<Object>

    var body: some View {
        Button(
            action: vm.remember,
            label: { DeviceListCell(state, vm) }
        )
            .buttonStyle(.borderless)
            .onAppear(perform: vm.onAppear)
    }
}
