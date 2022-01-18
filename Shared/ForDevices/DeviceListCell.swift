import SwiftUI
import CoreBluetooth

protocol DeviceCellParentVM {
    associatedtype O: ObservableObject

    var name:          KeyPath<O, String>               { get }
    var rssi:          KeyPath<O, Int>                  { get }
    var connection:    KeyPath<O, CBPeripheralState>    { get }
    var isCloudSynced: KeyPath<O, Bool>                 { get }
    var rename:        ((String) -> Void)?              { get }
    var onAppear:      () -> Void                       { get }
}

extension DeviceCellParentVM {

    func makeCellVM(_ o: O) -> DeviceListCell.VM {
        .init(name: o[keyPath: name],
              rssi: o[keyPath: rssi].formatted(.number),
              connection: o[keyPath: connection],
              rename: o[keyPath: connection].isConnected ? rename : nil,
              isCloudSynced: o[keyPath: isCloudSynced])
    }
}

struct DeviceListCell: View {

    struct VM {
        let name: String
        let rssi: String
        let connection: CBPeripheralState
        let rename: ((String) -> Void)?
        let isCloudSynced: Bool
    }

    init<Parent: DeviceCellParentVM>(_ parent: Parent.O, _ state: Parent) {
        self.vm = state.makeCellVM(parent)
        self.name = vm.name
    }

    @State private var name: String
    private let vm: VM


    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            if vm.rename == nil || vm.isCloudSynced {
                Text(vm.name)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                TextField("", text: $name, prompt: nil)
                    .onSubmit { vm.rename?(name) }
                    .font(.body.weight(.medium))
                    .frame(maxWidth: 200)
            }

            Spacer(minLength: 0)

            Text(vm.rssi)
                .foregroundColor(.secondary)
                .lineLimit(1)
                .fixedSize(horizontal: false, vertical: true)

            connectionIndicator
                .font(.callout.bold())
                .foregroundColor(vm.connection.isConnected ? .orange : .secondary)
                .frame(width: 25)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .animation(.easeOut, value: vm.connection)
    }

    @ViewBuilder private var connectionIndicator: some View {
        switch vm.connection {
            case .connecting:
                CircularBusyIndicator()

            default:
                if vm.isCloudSynced {
                    Image(systemName: "icloud")
                } else {
                    Image(systemName: "bolt.horizontal")
                        .symbolVariant(vm.connection.isConnected ? .fill : .none)
                }
        }
    }
}
