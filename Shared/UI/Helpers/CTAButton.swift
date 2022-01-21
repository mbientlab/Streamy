import SwiftUI

struct CTAButton: View {

    let cta: String
    var showSpinner: Bool = false
    let action: () -> Void
    var insets: EdgeInsets = .init(top: 12, leading: 30, bottom: 12, trailing: 30)
    var role: ButtonRole? = nil

    @Environment(\.isEnabled) private var isEnabled

    private var reverseOutColor: Color {
#if os(macOS)
        Color(.windowBackgroundColor)
#elseif os(iOS)
        Color(.systemBackground)
#endif
    }

    var body: some View {
        Button.init(role: role, action: action, label: {
            contents
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
                .padding(.horizontal, 8)
                .foregroundColor(reverseOutColor)
                .background(isEnabled ? Color.accentColor : Color.secondary.opacity(0.5) )
                .background(in: RoundedRectangle(cornerRadius: 12))

        })
            .buttonStyle(CTAButtonStyle())
            .padding(insets)
            .animation(.easeIn, value: isEnabled)
    }

    @State private var spin = false
    private var contents: some View {
        HStack(spacing: 20) {

            if showSpinner {
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(lineWidth: 2)

                    .rotationEffect(spin ? .degrees(360) : .zero)
                    .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: spin)
                    .onAppear { spin.toggle() }
                    .frame(maxWidth: 10, maxHeight: 10)
                    .colorMultiply(reverseOutColor)
            }

            Text(cta)
                .font(.title2.weight(.medium))
        }
        .animation(.easeIn, value: showSpinner)
    }
}

fileprivate struct CTAButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.9 : 1)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}
