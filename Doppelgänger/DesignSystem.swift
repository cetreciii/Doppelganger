import SwiftUI

// MARK: - Colors

extension Color {
    static let canvas = Color(hex: "faf9f7")
    static let ink = Color.black
    static let warmSilver = Color(hex: "9f9b93")
    static let warmCharcoal = Color(hex: "55534e")

    static let oatBorder = Color(hex: "696762")
    static let oatLight = Color(hex: "eee9df")
    static let darkBorder = Color(hex: "aabbda")

    static let matcha300 = Color(hex: "84e7a5")
    static let matcha600 = Color(hex: "078a52")
    static let matcha800 = Color(hex: "02492a")

    static let slushie500 = Color(hex: "3bd3fd")
    static let slushie800 = Color(hex: "0089ad")

    static let lemon400 = Color(hex: "f8cc65")
    static let lemon500 = Color(hex: "fbbd41")
    static let lemon700 = Color(hex: "d08a11")
    static let lemon800 = Color(hex: "9d6a09")

    static let ube300 = Color(hex: "c1b0ff")
    static let ube800 = Color(hex: "43089f")
    static let ube900 = Color(hex: "32037d")
    static let ubeDeep = Color(hex: "160040")

    static let pomegranate400 = Color(hex: "fc7981")

    static let blueberry800 = Color(hex: "01418d")

    init(hex: String) {
        let scanner = Scanner(string: hex)
        var int: UInt64 = 0
        scanner.scanHexInt64(&int)
        self.init(
            red: Double((int >> 16) & 0xFF) / 255,
            green: Double((int >> 8) & 0xFF) / 255,
            blue: Double(int & 0xFF) / 255
        )
    }
}

// MARK: - Typography
// Requires Roobert-Regular, Roobert-Medium, and Roobert-SemiBold font files
// added to the Xcode project and declared in Info.plist under UIAppFonts.

extension Font {
    static func roobert(_ size: CGFloat, weight: Weight = .regular) -> Font {
        let name: String
        if weight == .semibold || weight == .bold || weight == .heavy || weight == .black {
            name = "Roobert-SemiBold"
        } else if weight == .medium {
            name = "Roobert-Medium"
        } else {
            name = "Roobert-Regular"
        }
        return .custom(name, size: size)
    }
}

// MARK: - Button Styles

struct PlayfulPillButtonStyle: ButtonStyle {
    var background: Color
    var foreground: Color
    var shadowOffset: CGFloat = 5

    @Environment(\.colorScheme) private var colorScheme

    func makeBody(configuration: Configuration) -> some View {
        let shadowColor: Color = colorScheme == .dark ? .ubeDeep : .black

        return configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .foregroundStyle(foreground)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(background)
                    .shadow(
                        color: shadowColor,
                        radius: 0,
                        x: configuration.isPressed ? -2 : -shadowOffset,
                        y: configuration.isPressed ? 2 : shadowOffset
                    )
            )
            .offset(
                x: configuration.isPressed ? -(shadowOffset - 2) : 0,
                y: configuration.isPressed ? (shadowOffset - 2) : 0
            )
            .animation(.spring(response: 0.2, dampingFraction: 0.55), value: configuration.isPressed)
    }
}
