import SwiftUI

struct CircularBusyIndicator: View {

    var body: some View {
        ProgressView()
            .progressViewStyle(.circular)
        #if os(macOS)
            .controlSize(.small)
        #endif
    }
}
