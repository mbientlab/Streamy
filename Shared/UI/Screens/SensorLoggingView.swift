import Foundation
import SwiftUI
import MetaWear
import MetaWearSync

struct SensorLoggingView: View {

    init(mac: MACAddress, root: Root) {
        _logging = .init(wrappedValue: .init(mac: mac, sync: root.syncedDevices))
    }
    @EnvironmentObject private var root: Root
    @StateObject private var logging: SensorLoggingController

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            setup
            Spacer()
            HStack(spacing: ctaSpacing) {
                ctaButtons
                    .disabled(logging.enableCTAs == false)
                    .allowsHitTesting(logging.enableCTAs)
            }
            .font(ctaFont)
            .frame(maxWidth: .infinity, alignment: . center)
        }
        .frame(maxWidth: maxWidth, maxHeight: .infinity)
        .padding(.bottom, bottomPadding)
        .padding()
        .navigationTitle(logging.name)
        .animation(.easeOut, value: logging.state)
        .controlSize(.large)
        .onAppear(perform: logging.onAppear)
#if os(iOS)
        .toggleStyle(SwitchToggleStyle(tint: .orange))
#endif
    }

#if os(macOS)
    let ctaSpacing: CGFloat     = 30
    let ctaFont: Font?          = nil
    let maxWidth: CGFloat?      = .infinity
    let bottomPadding: CGFloat  = 25
#else
    let ctaSpacing: CGFloat     = 60
    let ctaFont: Font?          = .title3
    let maxWidth: CGFloat?      = 500
    let bottomPadding: CGFloat  = 50
#endif

    @ViewBuilder private var setup: some View {
        Text("Log Sensors").font(.title.weight(.medium))
        ForEach(logging.availableSensors) { sensor in
            Toggle(isOn: logging.toggleSensor(sensor)) { Text(sensor.name) }
        }
    }

    @ViewBuilder private var ctaButtons: some View {
        switch logging.state {

                /// This demo app does not track logging state between sessions.
            case .unknown:
                download
                startLogging.keyboardShortcut(.defaultAction)

            case .logging:
                CircularBusyIndicator()
                download.keyboardShortcut(.defaultAction)

            case .downloaded:
                Button("Export") { logging.export() }
                .keyboardShortcut(.defaultAction)
                .fileExporter(isPresented: $logging.showFolderExporter,
                              document: logging.exportable,
                              contentType: .folder,
                              defaultFilename: logging.exportable?.name) { result in
                    guard case let .failure(error) = result else { return }
                    logging.reportExportError(error)
                }

            case .downloading(let percentage):
                ProgressView("Downloading", value: percentage, total: 1)
                    .frame(width: 200)

            case .loggingError(let error):  Text(error)
            case .downloadError(let error): Text(error)
            case .exportError(let error):   Text(error)
        }
    }

    private var startLogging: some View {
        Button("Start Logging") { logging.log() }
        .disabled(logging.selectedSensors.isEmpty)
        .allowsHitTesting(logging.selectedSensors.isEmpty == false)
    }

    private var download: some View {
        Button("Download") { logging.download() }
    }

}
