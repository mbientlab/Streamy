import SwiftUI
import StreamyLogic

struct NextStepsViewModel<O: ObservableObject> {
    let title:     KeyPath<O, String>
    let ctas:      () -> [UseCaseCTA]
    let enableCTA: KeyPath<O, Bool>
    let didTapCTA: () -> Void
    let onAppear:  () -> Void
}

// MARK: - Variants for iOS vs macOS NavigationView Requirements
// In macOS, as a middle column view, the "new session" CTA should disappear after navigation to start that new session. This requires explicit control and response to a NavigationLink activated in the background.

struct NextStepsView_StackNavStyle<Object: ObservableObject>: View {

    init(_ observable: Observed<Object, NextStepsViewModel<Object>>) {
        _state = .init(wrappedValue: observable.object)
        self.vm = observable.vm
    }
    @StateObject private var state: Object
    private let vm: NextStepsViewModel<Object>
    @Environment(\.routedDevice) private var device

    var body: some View {
        Components.BaseView(state, vm, cta: ctas)
    }

    @ViewBuilder private var ctas: some View {
        let ctas = vm.ctas()
        if ctas != [.connect] {
            ForEach(ctas) { cta in
                NavigationLink(
                    destination: {
                        Components.Destinations(cta: cta)
                            .environment(\.routedDevice, device)
                    }, label: { Text(cta.displayName) }
                ).buttonStyleCTA()
            }
        } else {
            ForEach(ctas) { cta in
                Components.CTA(
                    cta: cta,
                    action: { _ in vm.didTapCTA() },
                    enable: state[keyPath: vm.enableCTA]
                )
            }
        }
    }
}


struct NextStepsView_MiddleColumnNavStyle<Object: ObservableObject>: View {

    init(_ observable: Observed<Object, NextStepsViewModel<Object>>) {
        _state = .init(wrappedValue: observable.object)
        self.vm = observable.vm
    }

    @StateObject private var state: Object
    private let vm: NextStepsViewModel<Object>
    @Environment(\.explicitNavigationTarget) private var target
    @State private var didNavigate = false
    private var allowNavigation: Bool { vm.ctas() != [.connect] }

    var body: some View {
        Components.BaseView(state, vm, cta: ctas)
            .animation(.easeIn, value: didNavigate)
            .frame(minWidth: 270)
    }

    @ViewBuilder private var ctas: some View {
        if !didNavigate {
            ForEach(vm.ctas()) { cta in
                Components.CTA(cta: cta,
                               action: interceptCTATapForNavigation,
                               enable: state[keyPath: vm.enableCTA])
            }
        }
    }

    /// Explicit navigation for three pane layout
    private func interceptCTATapForNavigation(_ cta: UseCaseCTA) {
        vm.didTapCTA()
        guard allowNavigation else { return }
        didNavigate = true
        target.wrappedValue = cta
    }
}

// MARK: - Base Implementation Components

fileprivate struct Components {

    struct BaseView<CTAConfiguration: View, Object: ObservableObject>: View {

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

                VStack(alignment: .center, spacing: .verticalSpacing / 2) {
                    ctaConfiguration
                }
            }
            .navigationTitle(state[keyPath: vm.title])
            .frame(maxWidth: .infinity, maxHeight:  .infinity)
            .screenPadding()
            .onAppear(perform: vm.onAppear)
        }
    }

    struct CTA: View {

        let cta: UseCaseCTA
        let action: (UseCaseCTA) -> Void
        let enable: Bool

        var body: some View {
            Button(cta.displayName, action: { action(cta) })
                .buttonStyleCTA(showSpinner: cta == .connect)
                .disabled(!enable)
                .allowsHitTesting(enable)
        }
    }

    struct Destinations: View {

        let cta: UseCaseCTA

        var body: some View {
            switch cta {
                case .predict:   Views.Predict()
                case .configure: Views.NewSession()
                case .download:  Views.Download()
                default: WhoopsView()
            }
        }
    }
}
