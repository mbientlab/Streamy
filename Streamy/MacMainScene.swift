import SwiftUI
import MetaWear

struct MainWindowScene: Scene {
    
    @StateObject var factory: UIFactory

    var body: some Scene {
        WindowGroup(id: "Main") {
            NavigationView {
                Views.DeviceList.SidebarList()
                    .frame(minWidth: 200)
                EmptyView()
                EmptyView()
            }
            .navigationViewStyle(.automatic)
            .frame(minWidth: 650, minHeight: 300)
            .toolbar { BluetoothStateToolbar() }
            .environmentObject(factory)
        }
        .commands {
            SidebarCommands()
            CommandGroup(replacing: .help) { }
            CommandGroup(replacing: .newItem) { }
        }
    }
}
