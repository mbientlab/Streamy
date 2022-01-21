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

//#if os(macOS)
//let ctaSpacing: CGFloat     = 30
//let ctaFont: Font?          = nil
//let maxWidth: CGFloat?      = .infinity
//let bottomPadding: CGFloat  = 25
//#else
//let ctaSpacing: CGFloat     = 60
//let ctaFont: Font?          = .title3
//let maxWidth: CGFloat?      = 500
//let bottomPadding: CGFloat  = 50
//#endif
