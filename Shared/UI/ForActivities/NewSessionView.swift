import SwiftUI
import MetaWear
import MetaWearSync

struct NewSessionViewModel<O: ObservableObject> {
    let title:     KeyPath<O, String>
    let ctaLabel:  KeyPath<O, String>
    let cta:       KeyPath<O, UseCaseCTA>
    let menu:      KeyPath<O, [MWNamedSignal]>
    let selection: KeyPath<O, Set<MWNamedSignal>>
    let isWorking: KeyPath<O, Bool>
    let enableCTA: KeyPath<O, Bool>
    let didTapCTA: () -> Void
    let toggle:    (_ selection: MWNamedSignal) -> Void
}

struct NewSessionView<State: ObservableObject>: View {

    init(_ observable: (object: State, vm: NewSessionViewModel<State>)) {
        _state = .init(wrappedValue: observable.object)
        self.vm = observable.vm
    }

    @StateObject private var state: State
    private let vm: NewSessionViewModel<State>
    @Environment(\.explicitNavigationTarget) private var target

    var body: some View {
        VStack(alignment: .leading, spacing: .verticalSpacing) {

            ScreenTitle(title: state[keyPath: vm.title])

            List {
                sensorChoices
            }
            .listStyle(.inset)

            #if os(macOS)
            ctaButton
            #elseif os(iOS)
            if state[keyPath: vm.cta] == .download {
                ctaNavigation
            } else { ctaButton }
            #endif
        }
        .animation(.easeOut, value: state[keyPath: vm.ctaLabel])
        .animation(.easeOut, value: state[keyPath: vm.enableCTA])
        .animation(.easeOut, value: state[keyPath: vm.selection])
        .screenPadding()
        .navigationTitle("New Session")
        .frame(maxWidth: .infinity, maxHeight:  .infinity)
    }

    private var ctaNavigation: some View {
        NavigationLink(
            destination: { Views.Download() },
            label: { ctaButton }
        )
    }

    private var ctaButton: some View {
        CTAButton(
            cta: state[keyPath: vm.ctaLabel],
            showSpinner: state[keyPath: vm.isWorking],
            action: interceptCTATapForNavigation
        )
            .disabled(!state[keyPath: vm.enableCTA])
            .allowsHitTesting(state[keyPath: vm.enableCTA])
    }

    private func interceptCTATapForNavigation() {
        #if os(macOS)
        vm.didTapCTA()
        // Explicit navigation for three pane layout
        if state[keyPath: vm.cta] == .download {
            target.wrappedValue = .download
        }
        #elseif os(iOS)
        vm.didTapCTA()
        #endif
    }

    private var sensorChoices: some View {
        Section {
            ForEach(state[keyPath: vm.menu]) { sensor in
                Toggle(isOn: toggle(sensor), label: { Text(sensor.id) })
            }
        } header: { Text("Sensors") }
#if os(iOS)
        .toggleStyle(SwitchToggleStyle(tint: .orange))
#endif
    }

    private func toggle(_ choice: MWNamedSignal) -> Binding<Bool> {
        .init(get: { state[keyPath: vm.selection].contains(choice) },
              set: { _ in vm.toggle(choice) })
    }
}
