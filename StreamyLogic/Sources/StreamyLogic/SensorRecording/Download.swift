import SwiftUI
import MetaWear
import MetaWearSync
import Combine
import CoreBluetooth

/// Downloads logged data from a MetaWear, offering it for export in CSV fomat.
///
public class DownloadUseCase: ObservableObject {

    public private(set) var startDate:         Date

    @Published public private(set) var export: ExportUseCase? = nil
    @Published public private(set) var cta:    UseCaseCTA     = .export
    @Published public private(set) var state:  UseCaseState   = .notReady
    public let deviceName:                     String

    @Published public var confirmSplitting:    Bool           = false
    private var cachedTables:                  [MWDataTable]  = []

    private weak var metawear:          MetaWear?         = nil
    private var actionSub:              AnyCancellable?   = nil

    public init(_ knownDevice: MWKnownDevice, startDate: Date) {
        self.startDate = startDate
        self.metawear = knownDevice.mw
        self.deviceName = knownDevice.meta.name
    }
}

public extension DownloadUseCase {

    func onAppear() {
        guard state == .notReady, let metawear = metawear else { return }
        actionSub = SDKAction
            .downloadLogs(
                from: metawear,
                startDate: startDate,
                progressEstimate: { [weak self] in self?.state = .workingProgress($0) }
            )
            .sink(
                receiveCompletion: { [weak self] in displayError(from: $0, on: self, \.state) },
                receiveValue:      { [weak self] in self?.prepareForExport(dataTables: $0) }
            )
    }

    func didTapCTA() {
        export?.showExportModal = true
    }

    func didChooseToSplitCSVColumns(byButtonPresses: Bool) {
        let cache = cachedTables
        let option = byButtonPresses
        ? LoggingBehavior.startLazilyPausePlayLoggersOnButtonDownUp
        : .startImmediatelyNoSplits

        DispatchQueue.global().async {
            self.completeExport(cache, option: option)
        }
    }
}

private extension DownloadUseCase {

    func prepareForExport(dataTables: [MWDataTable]) {
        guard dataTables.contains(where: { $0.source == .mechanicalButton }) else {
            completeExport(dataTables, option: .startImmediatelyNoSplits)
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.cachedTables = dataTables
            self?.confirmSplitting = true
        }
    }

    func completeExport(_ dataTables: [MWDataTable], option: LoggingBehavior) {
        let date = startDate.formatted(date: .abbreviated, time: .shortened)
        let csvs = SDKAction.convertToCSVs(dataTables, filenameTag: date, options: option)
        DispatchQueue.main.async { [weak self] in
            self?.state = .workingIndefinite

            self?.export = ExportUseCase(
                csvs: csvs,
                folderName: date,
                didPrepareExport: { [weak self] in
                    switch $0 {
                        case .success: self?.state = .ready
                        case .failure(let error): self?.state = .error(error)
                    }
                })
        }
    }
}
