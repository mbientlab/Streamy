import SwiftUI

struct BluetoothStateToolbar: ToolbarContent {
    let root: Root
    var body: some ToolbarContent {
        ToolbarItem(id: "Bluetooth", placement: .automatic, showsByDefault: true) {
            ToggleButton(root: root)
        }
    }

    struct ToggleButton: View {
        init(root: Root) {
            _state = .init(wrappedValue: .init(root.scanner))
        }
        @StateObject private var state: BluetoothStateVM

        var body: some View {
            buttonStates
                .onAppear(perform: state.onAppear)
        }
    }
}

extension BluetoothStateToolbar.ToggleButton {

    @ViewBuilder private var buttonStates: some View {
        if state.showError { permissionsCTA }
        else { scanToggle }
    }

    private var permissionsCTA: some View {
        Button("Authorize Bluetooth") { state.showBluetoothSettings() }
        .foregroundColor(.pink)
    }

    private var scanToggle: some View {
        HStack {
#if os(macOS)
            Image(nsImage: NSImage(named: NSImage.bluetoothTemplateName)!)
#endif
            Toggle(isOn: toggleScanning, label: {
                Text("Scan for Nearby Devices")
                    .frame(maxWidth: .infinity, alignment: .leading)
            })
                .toggleStyle(SwitchToggleStyle(tint: .orange))
                .animation(.easeOut, value: state.isScanning)
        }
    }

    private var toggleScanning: Binding<Bool> {
        Binding(get: { state.isScanning },
                set: { _ in state.toggleScanning() })
    }
}
