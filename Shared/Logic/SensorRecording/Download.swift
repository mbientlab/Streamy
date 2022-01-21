import SwiftUI
import MetaWear
import MetaWearSync
import Combine
import CoreBluetooth

/// Downloads logged data from a MetaWear, offering it for export in CSV fomat.
///
class DownloadUseCase: ObservableObject {

    private(set) var startDate:         Date

    @Published private(set) var export: ExportUseCase? = nil
    @Published private(set) var cta:    UseCaseCTA        = .export
    @Published private(set) var state:  UseCaseState      = .notReady
    let deviceName:                     String

    private weak var metawear:          MetaWear?         = nil
    private var actionSub:              AnyCancellable?   = nil

    init(_ knownDevice: MWKnownDevice, startDate: Date) {
        self.startDate = startDate
        self.metawear = knownDevice.mw
        self.deviceName = knownDevice.meta.name
    }
}

extension DownloadUseCase {

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
}

private extension DownloadUseCase {

    func prepareForExport(dataTables: [MWDataTable]) {
        let prefix = startDate.formatted(date: .abbreviated, time: .shortened)
        let csvs = SDKAction.convertToCSVs(dataTables, filenamePrefix: prefix)

        DispatchQueue.main.async { [weak self] in
            self?.state = .workingIndefinite

            self?.export = ExportUseCase(
                csvs: csvs,
                folderName: prefix,
                didPrepareExport: { [weak self] in
                    switch $0 {
                        case .success: self?.state = .ready
                        case .failure(let error): self?.state = .error(error)
                    }
                })
        }
    }
}
