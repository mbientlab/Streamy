import SwiftUI

/// macOS and iPad use a three-column split view.
///
/// SwiftUI, at least in 2021, disables a NavigationLink in the right-most view, which prevents those views from linking to each other, which Streamy would like to do.
///
/// Instead, the middle column parent must manage a set of invisible, explicitly activated NavigationLinks. This is a wrapper for the middle column so it and the third pane can manage navigation together.
///
struct ThirdPaneRouter<Pane: View>: View {

    @State private var target: UseCaseCTA? = nil
    @Environment(\.routedDevice) var device

    let middle: Pane

    var body: some View {
        middle
            .background(links.hidden())
            .environment(\.explicitNavigationTarget, $target)
    }

    @ViewBuilder var links: some View {
        NavigationLink(
            isActive: $target.isActive(.configure),
            destination: {
                Views.NewSession()
                    .environment(\.routedDevice, device)
                    .environment(\.explicitNavigationTarget, $target)
            }, label: { EmptyView() }
        )

        NavigationLink(
            isActive: $target.isActive(.download),
            destination: {
                Views.Download()
                    .environment(\.routedDevice, device)
                    .environment(\.explicitNavigationTarget, $target)
            }, label: { EmptyView() }
        )
    }
}

extension EnvironmentValues {

    var explicitNavigationTarget: Binding<UseCaseCTA?> {
        get { return self[ExplicitNavigationEVK.self] }
        set { self[ExplicitNavigationEVK.self] = newValue }
    }
}

fileprivate struct ExplicitNavigationEVK: EnvironmentKey {
    static let defaultValue: Binding<UseCaseCTA?> = .constant(nil)
}
