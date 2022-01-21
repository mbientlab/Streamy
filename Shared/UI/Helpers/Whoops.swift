import SwiftUI

struct WhoopsView: View {

    var error: Error?
    var message: String?

    private var title: String { message ?? "Whoops" }
    private var detail: String { error?.localizedDescription ?? "Something happened that never should." }

    var body: some View {
        VStack(alignment: .leading) {
            ScreenTitle(title: title, subtitle: detail)
        }
        .navigationTitle("Whoops")
    }
}

struct WhoopsRow: View {

    var error: Error?
    var message: String?

    private var title: String { message ?? "Whoops" }
    private var detail: String { error?.localizedDescription ?? "Unknown error" }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.callout.weight(.medium))
                .foregroundColor(.secondary)

            Text(detail).font(.caption)
        }
    }
}
