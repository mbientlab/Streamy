import SwiftUI

@main
struct MacApp: App {
    @NSApplicationDelegateAdaptor private var app: AppDelegate

    var body: some Scene {
        MainWindowScene(factory: .init(root: app.root))
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    let root = Root()

    func applicationDidFinishLaunching(_ n: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
        root.start()
    }
}
