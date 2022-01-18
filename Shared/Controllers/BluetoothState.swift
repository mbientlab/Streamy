import SwiftUI
import MetaWear
import Combine
import CoreBluetooth

class BluetoothStateVM: ObservableObject {

    @Published private(set) var isScanning: Bool
    @Published private var state:           CBManagerState
    public var showError:                   Bool { state.isProblematic }

    private weak var scanner: MetaWearScanner?
    private var scannerSub:   AnyCancellable? = nil
    private var bluetoothSub: AnyCancellable? = nil

    init(_ scanner: MetaWearScanner) {
        self.scanner = scanner
        self.isScanning = scanner.isScanning
        self.state = scanner.central.state
    }
}

extension BluetoothStateVM  {

    func onAppear() {
        scannerSub = scanner?.isScanningPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.isScanning = $0 }

        bluetoothSub = scanner?.bluetoothState
            .receive(on: DispatchQueue.main, options: nil)
            .sink { [weak self] in self?.state = $0  }
    }

    func toggleScanning() {
        if isScanning { scanner?.stopScan() }
        else { scanner?.startScan(higherPerformanceMode: true) }
    }

    func showBluetoothSettings() {
#if os(macOS)
        if let ctaURL = state.ctaURL { NSWorkspace.shared.open(ctaURL) }
#elseif os(iOS)
        if let ctaURL = state.ctaURL { UIApplication.shared.open(ctaURL) }
#endif
    }
}

fileprivate extension CBManagerState {

    var ctaURL: URL? {
#if os(macOS)
        let bluetoothURL   = URL(fileURLWithPath: "/System/Library/PreferencePanes/Bluetooth.prefPane")
        let appSettingsURL = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Bluetooth")!
#else
        let bluetoothURL   = URL(string: UIApplication.openSettingsURLString)
        let appSettingsURL = URL(string: UIApplication.openSettingsURLString)
#endif

        switch self {
            case .poweredOff: return bluetoothURL
            case .unauthorized: return appSettingsURL
            case .unsupported: return bluetoothURL
            default: return nil
        }
    }
}