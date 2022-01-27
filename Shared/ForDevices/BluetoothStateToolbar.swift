import SwiftUI

struct BluetoothStateViewModel<O: ObservableObject> {
    let showError:      KeyPath<O, Bool>
    let isScanning:     KeyPath<O, Bool>
    let toggleScanning: () -> Void
    let showSettings:   () -> Void
    let onAppear:       () -> Void
}

struct BluetoothStateToolbar: ToolbarContent {

    var body: some ToolbarContent {
        ToolbarItem(id: "Bluetooth", placement: .automatic, showsByDefault: true) {
            Views.BluetoothToggle()
        }
    }
}

struct BluetoothStateToggleButton<Object: ObservableObject>: View {

    init(_ observable: Observed<Object, BluetoothStateViewModel<Object>>) {
        _state = .init(wrappedValue: observable.object)
        self.vm = observable.vm
    }

    @StateObject private var state: Object
    let vm: BluetoothStateViewModel<Object>

    var body: some View {
        buttonStates
            .onAppear(perform: vm.onAppear)
    }
}

extension BluetoothStateToggleButton {

    @ViewBuilder private var buttonStates: some View {
        if state[keyPath: vm.showError] { permissionsCTA }
        else { scanToggle }
    }

    private var permissionsCTA: some View {
        Button("Authorize Bluetooth") { vm.showSettings() }
        .foregroundColor(.pink)
    }

    private var scanToggle: some View {
        HStack {
#if os(macOS)
            Image(nsImage: NSImage(named: NSImage.bluetoothTemplateName)!)
#endif
            Toggle(isOn: toggleScanning, label: {
                Text("Scan for Nearby Devices")
                #if os(iOS)
                    .frame(maxWidth: .infinity, alignment: .leading)
                #endif
            })
                .toggleStyle(SwitchToggleStyle(tint: .orange))
                .animation(.easeOut, value: state[keyPath: vm.isScanning])
        }
    }

    private var toggleScanning: Binding<Bool> {
        Binding(get: { state[keyPath: vm.isScanning] },
                set: { _ in vm.toggleScanning() })
    }
}
