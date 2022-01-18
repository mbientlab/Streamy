import SwiftUI
import StreamyLogic

struct DownloadViewModel<O: ObservableObject> {
    let title:     KeyPath<O, String>
    let ctaLabel:  KeyPath<O, String>
    let enableCTA: KeyPath<O, Bool>
    let state:     KeyPath<O, UseCaseState>
    let export:    KeyPath<O, ExportUseCase?>
    let didTapCTA: () -> Void
    let onAppear:  () -> Void
}

struct DownloadView<Object: ObservableObject>: View {

    init(_ observable: (object: Object, vm: DownloadViewModel<Object>)) {
        _state = .init(wrappedValue: observable.object)
        self.vm = observable.vm
    }

    @StateObject private var state: Object
    private let vm: DownloadViewModel<Object>

    private func label(_ percent: Double) -> String {
        let percentage = Int(percent * 100)
        return "Downloading... \(percentage.formatted(.percent))"
    }

    var body: some View {
        VStack(alignment: .center, spacing: .verticalSpacing) {

            ScreenTitle(title: state[keyPath: vm.title])

            Spacer()
            progress
            Spacer()

            if let export = state[keyPath: vm.export] {
                ExportIcon(exporter: export)
            }
            ctaButton
        }
        .onAppear(perform: vm.onAppear)
        .screenPadding()
        .navigationTitle("Download")
        .frame(maxWidth: .infinity, maxHeight:  .infinity)
        .animation(.easeIn, value: state[keyPath: vm.export] == nil)
        .animation(.easeIn, value: state[keyPath: vm.state])
    }

    private var ctaButton: some View {
        Button(state[keyPath: vm.ctaLabel], action: vm.didTapCTA)
            .buttonStyleCTA()
            .disabled(state[keyPath: vm.enableCTA] == false)
            .allowsHitTesting(state[keyPath: vm.enableCTA])
    }

    @ViewBuilder private var progress: some View {
        switch state[keyPath: vm.state] {
            case .workingProgress(let percent):
                ProgressView(label(percent), value: percent, total: 1)
                    .frame(width: 200)
                    .animation(.easeOut(duration: 2), value: percent)

            case .workingIndefinite:
                Text("Preparing CSVs")
                CircularBusyIndicator()

            case .error(let error):
                WhoopsRow(error: error)

            case .ready:
                Text("CSVs Ready")

            default: EmptyView()
        }
    }
}
