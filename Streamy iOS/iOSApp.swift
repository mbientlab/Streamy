import SwiftUI

@main
struct iOSApp: App {
    @UIApplicationDelegateAdaptor private var app: AppDelegate

    var body: some Scene {
        MainScene(factory: .init(root: app.root))
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {

    let root = Root()

    func applicationDidFinishLaunching(_ application: UIApplication) {
        root.start()
    }

    /// Force navigation sidebar to show in demo app
    func application(_ app: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .pad { return .landscape }
        else { return .all }
    }
}
