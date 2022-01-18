import SwiftUI

@main
struct MacApp: App {
    @StateObject private var root = Root()

    var body: some Scene {
        WindowGroup {
            NavigationView {
                DeviceListSidebar(root)
                    .frame(minWidth: 200)
                EmptyView()
            }
            .frame(minWidth: 650, minHeight: 300)
            .toolbar { BluetoothStateToolbar(root: root) }
            .onAppear(perform: root.start)
            .environmentObject(root)
        }
        .commands { SidebarCommands() }
    }
}
