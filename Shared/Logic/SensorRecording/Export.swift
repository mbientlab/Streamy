import Foundation
import UniformTypeIdentifiers

/// Organizes CSV data into a temporary folder suitable for export using SwiftUI's FileDocument API.
///
class ExportUseCase: ObservableObject {

    @Published var showExportModal:         Bool    = false
    @Published private(set) var isWorking:  Bool    = false
    @Published private(set) var exportable: Folder? = nil
    let exportType:                         UTType  = .folder

    private var files:                      [SDKAction.CSVFile]
    private let folderName:                 String
    private let tempDirectory:              URL
    private let didPrepareExport:           (Result<Void,Error>) -> Void

    init(csvs: [SDKAction.CSVFile], folderName: String, didPrepareExport: @escaping (Result<Void,Error>) -> Void) {
        self.files = csvs
        self.folderName = folderName
        self.tempDirectory = Self.getUniqueTemporaryDirectory()
        self.didPrepareExport = didPrepareExport
    }

    deinit { try? FileManager.default.removeItem(at: tempDirectory) }
}

extension ExportUseCase {

    func onAppear() {
        isWorking = true
        DispatchQueue.global().async { [weak self] in
            self?.prepareExport()
        }
    }
}

private extension ExportUseCase {

    func prepareExport() {
        guard files.hasElements else { return }

        do {
            let tempURL = try createExportableDirectory(named: folderName)
            for file in files {
                let url = tempURL.appendingPathComponent(file.filename).appendingPathExtension(for: .commaSeparatedText)
                try file.csv.write(to: url, options: .atomicWrite)
            }
            try DispatchQueue.main.sync { [weak self] in
                self?.files = []
                self?.exportable = try Folder(url: tempURL, name: folderName)
                self?.isWorking = false
                self?.didPrepareExport(.success(()))
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.didPrepareExport(.failure(error))
            }
        }
    }

    func createExportableDirectory(named: String) throws -> URL {
        let url = tempDirectory.appendingPathComponent(named, isDirectory: true)
        try? FileManager.default.removeItem(at: url)
        try FileManager.default.createDirectory(atPath: url.path, withIntermediateDirectories: true, attributes: nil)
        return url
    }

    static func getUniqueTemporaryDirectory(id: UUID = .init()) -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("\(Self.self) \(id.uuidString)", isDirectory: true)
    }
}
