import SwiftUI

@main
struct iOSApp: App {
    @UIApplicationDelegateAdaptor private var delegate: AppDelegate
    @StateObject private var root = Root()

    var body: some Scene {
        WindowGroup {
            NavigationView {
                DeviceListSidebar(root)
                EmptyView()
            }
            .navigationViewStyle(.columns)
            .onAppear(perform: root.start)
            .environmentObject(root)
        }
        .commands { SidebarCommands() }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {

    /// Force navigation sidebar to show in demo app
    func application(_ app: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .pad { return .landscape }
        else { return .all }
    }
}
