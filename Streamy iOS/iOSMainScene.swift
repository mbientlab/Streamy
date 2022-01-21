import SwiftUI

struct MainScene: Scene {

    @StateObject var factory: UIFactory

    var body: some Scene {
        WindowGroup {
            NavigationView {
                Views.DeviceList.SidebarList()
                EmptyView()
            }
            .navigationViewStyle(.columns)
            .environmentObject(factory)
        }
        .commands { SidebarCommands() }
    }
}
