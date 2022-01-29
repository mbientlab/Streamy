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
            .toolbar {
                BluetoothStateToolbar()
                ToolbarItemGroup(placement: .navigation) {
                    DownsampleButton()
                }

            }
            .environmentObject(factory)
        }
        .commands {
            SidebarCommands()
            CommandGroup(replacing: .help) { }
            CommandGroup(replacing: .newItem) { }
        }
    }
}

#endif

struct DownsampleButton: View {

    @State private var showPicker = false
    var body: some View {
        Button("Downsample") { showPicker = true }
        .fileImporter(isPresented: $showPicker, allowedContentTypes: [.folder], allowsMultipleSelection: true) { result in
            guard case let .success(urls) = result else { return }
            DispatchQueue.global().async {
                Downsampler.downsample(folders: urls)
            }
        }
    }
}

struct Downsampler {

    static func downsample(folders: [URL], divisibleBy offset: Int = 2) {
        let fm = FileManager.default

        for folder in folders {
            let csvs = try? fm
                .contentsOfDirectory(at: folder, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants)
                .filter { $0.pathExtension == "csv" }

            downsample(csvs: csvs ?? [])
        }

        DispatchQueue.main.async {
            NSWorkspace.shared.activateFileViewerSelecting(folders)
        }
    }

    static func downsample(csvs: [URL], divisibleBy offset: Int = 2) {
        let fm = FileManager.default
        for csvURL in csvs {
            guard let data = fm.contents(atPath: csvURL.path),
                  let csv = String(data: data, encoding: .utf8)?.components(separatedBy: .newlines)
            else { continue }

            let downsampled = csv
                .enumerated()
                .reduce(into: "") { newCSV, line in
                    if line.offset == 0 { newCSV += "\(line.element)\n"; return }
                    guard line.offset % 2 == 0 else { return }
                    newCSV += "\(line.element)\n"
                }

            try? downsampled.data(using: .utf8)?.write(to: csvURL, options: .atomic)
        }
    }
}
