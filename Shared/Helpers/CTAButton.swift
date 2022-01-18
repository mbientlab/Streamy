import SwiftUI

extension View {

    func buttonStyleCTA(showSpinner: Bool = false,
                        insets: EdgeInsets = .init(top: 12, leading: 30, bottom: 12, trailing: 30)
    ) -> some View {
        self.buttonStyle(CTAButtonStyle(showSpinner: showSpinner))
            .padding(insets)
    }
}

fileprivate struct CTAButtonStyle: ButtonStyle {

    var showSpinner: Bool

    func makeBody(configuration: Configuration) -> some View {
        Style(config: configuration, style: self)
    }

    struct Style: View {
        let config: Configuration
        let style: CTAButtonStyle
        @Environment(\.isEnabled) private var isEnabled
        @State private var spin = false

        var body: some View {
            label
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
                .padding(.horizontal, 8)
                .foregroundColor(reverseOutColor)
                .background(isEnabled ? Color.accentColor : Color.secondary.opacity(0.5) )
                .background(in: RoundedRectangle(cornerRadius: 12))
                .animation(.easeIn, value: isEnabled)

                .opacity(config.isPressed ? 0.9 : 1)
                .scaleEffect(config.isPressed ? 0.96 : 1)
                .animation(.easeOut(duration: 0.2), value: config.isPressed)
        }

        private var label: some View {
            HStack(spacing: 20) {
                if style.showSpinner {
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(lineWidth: 2)

                        .rotationEffect(spin ? .degrees(360) : .zero)
                        .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: spin)
                        .onAppear { spin.toggle() }
                        .frame(maxWidth: 10, maxHeight: 10)
                        .colorMultiply(reverseOutColor)
                }

                config.label
                    .font(.title2.weight(.medium))
            }
            .animation(.easeIn, value: style.showSpinner)
        }

        private var reverseOutColor: Color {
#if os(macOS)
            Color(.windowBackgroundColor)
#elseif os(iOS)
            Color(.systemBackground)
#endif
        }
    }
}
