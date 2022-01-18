import SwiftUI
import MetaWear
import CoreBluetooth

struct DeviceListSidebar: View {

    init(_ root: Root) {
        _list = .init(wrappedValue: DeviceListController(root.syncedDevices, root.scanner))
    }
    @EnvironmentObject private var root: Root
    @StateObject private var list: DeviceListController

    var body: some View {
        List {
#if os(iOS)
            BluetoothStateToolbar.ToggleButton(root: root)
#endif

            if list.knownDevices.isEmpty && list.unknownDevices.isEmpty {
                Text("Bring your MetaWears nearby")
            }

            if list.knownDevices.isEmpty == false {
                Section("My MetaWears") {
                    ForEach(list.knownDevices, id: \.self) { macAddress in
                        KnownDeviceCell(mac: macAddress, root: root)
                    }
                }
            }

            if list.unknownDevices.isEmpty == false {
                Section("Nearby") {
                    ForEach(list.unknownDevices, id: \.self) { localIdentifier in
                        UnknownDeviceCell(id: localIdentifier, root: root, parent: list)
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .animation(.easeOut, value: list.knownDevices)
        .animation(.easeOut, value: list.unknownDevices)
        .onAppear(perform: list.onAppear)
#if os(iOS)
        .navigationTitle("Connect")
#endif
    }
}

// MARK: - Two Types of Cells

extension DeviceListSidebar {

    struct UnknownDeviceCell: View {

        init(id: CBPeripheralIdentifier, root: Root, parent: DeviceListController) {
            _vm = .init(wrappedValue: .init(id: id, sync: root.syncedDevices, parent: parent))
        }
        @StateObject private var vm: UnknownDeviceController

        var body: some View {
            DeviceCell(
                name: vm.name,
                rssi: vm.rssi,
                connection: vm.isConnecting ? .connecting : .disconnected,
                rename: nil,
                isCloudSynced: vm.isCloudSynced
            )
                .onTapGesture(perform: vm.remember)
                .onAppear(perform: vm.onAppear)
        }
    }

    struct KnownDeviceCell: View {

        init(mac: MACAddress, root: Root) {
            _vm = .init(wrappedValue: .init(knownDevice: mac, sync: root.syncedDevices))
        }
        @EnvironmentObject private var root: Root
        @StateObject private var vm: KnownDeviceController
        @State private var rename = ""

        var body: some View {
            // If a local MetaWear instance isn't known,
            // don't allow navigation to interact with the non-existent MetaWear.
            if vm.isCloudSynced { cell } else {
                NavigationLink { destination } label: { cell }
                .onAppear(perform: vm.onAppear)
                .contextMenu { contextMenu }
                .alert("Invalid MetaWear Name",
                       isPresented: $vm.showRenamePrompt,
                       actions: { Button("Ok") { } },
                       message: { Text("MetaWear names can be up to 26 alphanumeric characters, including _, -, and spaces.") })
            }
        }

        private var destination: some View {
            SensorLoggingView(mac: vm.metadata.mac, root: root)
        }

        private var cell: some View {
            DeviceCell(
                name: vm.name,
                rssi: vm.rssi,
                connection: vm.connection,
                rename: vm.connection == .connected ? vm.rename : nil,
                isCloudSynced: vm.isCloudSynced
            )
        }

        @ViewBuilder private var contextMenu: some View {
            if vm.connection < .connecting {
                Button("Connect") { vm.connect() }
            } else {
                Button("Disconnect") { vm.disconnect() }
            }
            Button("Flash LEDs") { vm.identify() }
            Divider()
            Button("Forget") { vm.forget() }
        }
    }
}

// MARK: - Base Cell

extension DeviceListSidebar {

    struct DeviceCell: View {
        @State var name: String
        let rssi: Int
        let connection: CBPeripheralState
        let rename: ((String) -> Void)?
        let isCloudSynced: Bool

        var body: some View {
            HStack(alignment: .center, spacing: 10) {
                if rename == nil || isCloudSynced {
                    Text(name)
                        .fontWeight(.medium)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    TextField("", text: $name, prompt: nil)
                        .onSubmit { rename?(name) }
                        .font(.body.weight(.medium))
                        .frame(maxWidth: 200)
                }

                Spacer(minLength: 0)

                Text(rssi, format: .number)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .fixedSize(horizontal: false, vertical: true)

                connectionIndicator
                    .font(.callout.bold())
                    .foregroundColor(connection == .connected ? .orange : .secondary)
                    .frame(width: 25)
            }
            .contentShape(Rectangle())
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .animation(.easeOut, value: connection)
        }

        @ViewBuilder private var connectionIndicator: some View {
            switch connection {
                case .connecting:
                    CircularBusyIndicator()

                default:
                    if isCloudSynced {
                        Image(systemName: "icloud")
                    } else {
                        Image(systemName: "bolt.horizontal")
                            .symbolVariant(connection == .connected ? .fill : .none)
                    }
            }
        }
    }
}
