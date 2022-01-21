import SwiftUI
import MetaWear
import CoreBluetooth

struct DevicesListViewModel<O: ObservableObject> {
    let unknowns:  KeyPath<O, [CBPeripheralIdentifier]>
    let knowns:    KeyPath<O, [MACAddress]>
    let tasks:     KeyPath<O, UnownedCancellableStore>
    let onAppear:  () -> Void

    func showEmptyTip(_ o: O) -> Bool {
        o[keyPath: knowns].isEmpty && o[keyPath: unknowns].isEmpty
    }
}

struct DeviceListSidebar<Object: ObservableObject>: View {

    init(_ observable: (object: Object, vm: DevicesListViewModel<Object>)) {
        _state = .init(wrappedValue: observable.object)
        self.vm = observable.vm
    }

    @StateObject private var state: Object
    private let vm: DevicesListViewModel<Object>

    var body: some View {
        List {
#if os(iOS)
            Views.BluetoothToggle()
#endif
            if vm.showEmptyTip(state)  { tip }
            if state[keyPath: vm.knowns].hasElements   { known }
            if state[keyPath: vm.unknowns].hasElements { nearby }
        }
        .listStyle(.sidebar)
        .animation(.easeOut, value: state[keyPath: vm.unknowns])
        .animation(.easeOut, value: state[keyPath: vm.knowns])
        .onAppear(perform: vm.onAppear)
#if os(iOS)
        .navigationTitle("Connect")
#endif
    }

    private var tip: some View {
        Text("Bring your MetaWears nearby")
    }

    private var known: some View {
        Section("My MetaWears") {
            ForEach(state[keyPath: vm.knowns], id: \.self) { macAddress in
                Views.DeviceList.KnownCell(mac: macAddress)
                
            }
        }
    }

    private var nearby: some View {
        Section("Nearby") {
            ForEach(state[keyPath: vm.unknowns], id: \.self) { localIdentifier in
                Views.DeviceList.UnknownCell(id: localIdentifier, tasks: state[keyPath: vm.tasks])
            }
        }
    }
}
