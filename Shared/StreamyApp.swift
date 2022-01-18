import SwiftUI
import StreamyLogic

#if os(iOS)

@main
struct iOSApp: App {
    @UIApplicationDelegateAdaptor private var app: AppDelegate

    var body: some Scene {
        MainScene(factory: .init(root: app.root))
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {

    let root = Root(local: .standard, cloud: .default)

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        root.start()
        return true
    }

    func application(_ app: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .pad { return .landscape }
        else { return .all }
    }
}

#elseif os(macOS)

@main
struct MacApp: App {
    @NSApplicationDelegateAdaptor private var app: AppDelegate

    var body: some Scene {
        MainWindowScene(factory: .init(root: app.root))
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {

    let root = Root(local: .standard, cloud: .default)

    func applicationDidFinishLaunching(_ n: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
        root.start()
    }
}

#endif
