import SwiftUI

extension CGFloat {
    static let verticalSpacing: CGFloat = 30
}

extension EdgeInsets {
    static let screen = EdgeInsets(
        top: 20,
        leading: 20,
        bottom: 20,
        trailing: 20
    )
}

extension View {
    func screenPadding() -> some View {
        padding(.screen)
    }
}
