import SwiftUI

#if os(iOS)

struct MainScene: Scene {

    @StateObject var factory: UIFactory

    var body: some Scene {
        WindowGroup {
            if UIDevice.current.userInterfaceIdiom == .pad { iPad } else {
                NavigationView {
                    Views.DeviceList.SidebarList()
                }
                .navigationViewStyle(.stack)
                .environmentObject(factory)
            }
        }
        .commands { SidebarCommands() }
    }

    private var iPad: some View {
        NavigationView {
            Views.DeviceList.SidebarList()
                .onAppear(perform: findSplitViewControllerToOpenSidebar)
            EmptyView()
            EmptyView()
        }
        .navigationViewStyle(.columns)
        .navigationBarHidden(true)
        .environmentObject(factory)
    }

    private func findSplitViewControllerToOpenSidebar() {
        DispatchQueue.main.async {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .compactMap(\.rootViewController)
                .flatMap(\.children)
                .compactMap { $0 as? UISplitViewController }
                .forEach(animateSplitViewControllerOpening)
        }
    }

    private func animateSplitViewControllerOpening(_ vc: UISplitViewController) {
        UIView.animate(withDuration: 0.2) {
            vc.preferredDisplayMode = .twoBesideSecondary
        }
    }
}

#elseif os(macOS)

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
            CommandMenu("Data Wrangling") {
                DownsampleButton()
                ComputeDifferenceButton()
            }
        }
    }
}

#endif
