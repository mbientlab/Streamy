import SwiftUI
import StreamyLogic

struct ExportIcon: View {

    var exporter: ExportUseCase?

    var body: some View {
        if let exporter = exporter {
            Popup(exporter: exporter)
        }
    }

    struct Popup: View {
        @ObservedObject var exporter: ExportUseCase
        @State private var error: Error? = nil
    }

}

extension ExportIcon.Popup {

    var body: some View {

        CircularBusyIndicator()
            .opacity(exporter.isWorking ? 1 : 0)
            .onAppear(perform: exporter.onAppear)
            .alert(
                "Export Error",
                isPresented: $error.isPresented(),
                actions: { Button("Ok") { error = nil } },
                message: { Text(error?.localizedDescription ?? "Unknown") }
            )
            .fileExporter(
                isPresented: $exporter.showExportModal,
                document: exporter.exportable,
                contentType: exporter.exportType,
                defaultFilename: exporter.exportable?.name,
                onCompletion: { result in
                    switch result {
                        case .failure(let error):
                            self.error = error
                        case .success(let url):
                            #if os(macOS)
                            NSWorkspace.shared.activateFileViewerSelecting([url])
                            #endif
                    }
                }
            )
    }
}
