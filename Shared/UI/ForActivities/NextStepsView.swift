import SwiftUI

struct NextStepsViewModel<O: ObservableObject> {
    let title:     KeyPath<O, String>
    let ctaLabel:  KeyPath<O, String>
    let cta:       KeyPath<O, UseCaseCTA>
    let enableCTA: KeyPath<O, Bool>
    let didTapCTA: () -> Void
    let onAppear:  () -> Void
}

// MARK: - Variants for iOS vs macOS NavigationView Requirements
// In macOS, as a middle column view, the "new session" CTA should disappear after navigation to start that new session. This requires explicit control and response to a NavigationLink activated in the background.

struct NextStepsView_StackNavStyle<Object: ObservableObject>: View {

    init(_ observable: (object: Object, vm: NextStepsViewModel<Object>)) {
        _state = .init(wrappedValue: observable.object)
        self.vm = observable.vm
    }
    @StateObject private var state: Object
    private let vm: NextStepsViewModel<Object>

    var body: some View {
        Components.BaseView(state, vm, cta: ctas)
    }

    @ViewBuilder private var ctas: some View {
        if state[keyPath: vm.cta] != .connect {
            NavigationLink(
                destination: { Components.Destinations(state, vm) },
                label: { Components.CTA(state, vm, action: vm.didTapCTA) }
            )
        } else { Components.CTA(state, vm, action: vm.didTapCTA) }
    }
}


struct NextStepsView_MiddleColumnNavStyle<Object: ObservableObject>: View {

    init(_ observable: (object: Object, vm: NextStepsViewModel<Object>)) {
        _state = .init(wrappedValue: observable.object)
        self.vm = observable.vm
    }

    @StateObject private var state: Object
    private let vm: NextStepsViewModel<Object>

    @Environment(\.routedDevice) private var device
    @Environment(\.explicitNavigationTarget) private var target
    @State private var didNavigate = false
    private var allowNavigation: Bool { state[keyPath: vm.cta] != .connect }

    var body: some View {
        Components.BaseView(state, vm, cta: ctas)
            .animation(.easeIn, value: didNavigate)
            .frame(minWidth: 270)
    }

    @ViewBuilder private var ctas: some View {
        if !didNavigate {
            Components.CTA(state, vm, action: interceptCTATapForNavigation)
        }
    }

    /// Explicit navigation for three pane layout
    private func interceptCTATapForNavigation() {
        vm.didTapCTA()
        guard allowNavigation else { return }
        didNavigate = true
        target.wrappedValue = state[keyPath: vm.cta]
    }
}

// MARK: - Base Implementation Components

fileprivate struct Components<Object: ObservableObject> {

    struct BaseView<CTAConfiguration: View>: View {

        init(_ o: Object, _ vm: NextStepsViewModel<Object>, cta: CTAConfiguration) {
            (self.state, self.vm) = (o, vm)
            self.ctaConfiguration = cta
        }
        @ObservedObject private var state: Object
        private let vm: NextStepsViewModel<Object>
        private let ctaConfiguration: CTAConfiguration

        var body: some View {
            VStack(alignment: .leading, spacing: .verticalSpacing) {

                ScreenTitle(title: "Prior Sessions")

                Text("Your app could list prior sessions.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                ctaConfiguration
            }
            .navigationTitle(state[keyPath: vm.title])
            .frame(maxWidth: .infinity, maxHeight:  .infinity)
            .screenPadding()
            .onAppear(perform: vm.onAppear)
        }
    }

    struct CTA: View {

        init(_ o: Object, _ vm: NextStepsViewModel<Object>, action: @escaping () -> Void) {
            (self.state, self.vm) = (o, vm)
            self.action = action
        }
        @ObservedObject private var state: Object
        private let vm: NextStepsViewModel<Object>
        private let action: () -> Void

        var body: some View {
            CTAButton(
                cta: state[keyPath: vm.ctaLabel],
                showSpinner: state[keyPath: vm.cta] == .connect,
                action: action
            )
                .disabled(state[keyPath: vm.enableCTA] == false)
                .allowsHitTesting(state[keyPath: vm.enableCTA])
        }

    }

    struct Destinations: View {

        init(_ o: Object, _ vm: NextStepsViewModel<Object>) {
            (self.state, self.vm) = (o, vm)
        }
        @ObservedObject private var state: Object
        private let vm: NextStepsViewModel<Object>

        var body: some View {
            switch state[keyPath: vm.cta] {
                case .configure: Views.NewSession()
                case .download:  Views.Download()
                default: WhoopsView()
            }
        }
    }
}
