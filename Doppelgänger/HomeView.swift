import SwiftUI

struct HomeView: View {
    var onNewGame: () -> Void = {}

    @Environment(\.colorScheme) private var colorScheme

    private var isLight: Bool { colorScheme == .light }

    private var backgroundColor: Color { isLight ? .canvas : .ube900 }
    private var textColor: Color { isLight ? .ink : .white }
    private var cardBackground: Color { isLight ? .white : .ube800 }
    private var borderColor: Color { isLight ? .oatBorder : .darkBorder }
    private var secondaryText: Color { isLight ? .warmSilver : .ube300 }

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                titleCard
                    .padding(.horizontal, 24)

                Spacer().frame(height: 32)

                tagline
                    .padding(.horizontal, 40)

                Spacer().frame(height: 40)

                roleChips
                    .padding(.bottom, 50)

                Spacer()

                newGameButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 52)
            }
        }
    }

    // MARK: - Title Card

    private var titleCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(cardBackground)
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 1)
                .shadow(color: .black.opacity(0.05), radius: 0, x: 0, y: -1)

            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(style: StrokeStyle(lineWidth: 3, dash: [20, 5]))
                .foregroundStyle(borderColor)

            VStack(alignment: .leading, spacing: 8) {

                Text("Doppel\u{00AD}gänger")
                    .font(.roobert(58, weight: .semibold))
                    .tracking(-2.4)
                    .foregroundStyle(textColor)
                    .minimumScaleFactor(0.6)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .rotationEffect(.degrees(-2))
    }

    // MARK: - Tagline

    private var tagline: some View {
        Text("Unmask the AI.\nOutsmart the Pretender.")
            .font(.roobert(20, weight: .regular))
            .foregroundStyle(textColor)
            .multilineTextAlignment(.center)
            .lineSpacing(5)
    }

    // MARK: - Role Chips

    private var roleChips: some View {
        HStack(spacing: 10) {
            chip(label: "Normal", bg: .matcha300, fg: .matcha800, angle: 2.5)
            chip(label: "Pretender", bg: .pomegranate400, fg: .white, angle: -1.5)
            chip(label: "AI", bg: .ube800, fg: .white, angle: 1.0)
        }
        .padding(.horizontal, 24)
    }

    private func chip(label: String, bg: Color, fg: Color, angle: Double) -> some View {
        Text(label)
            .font(.roobert(13, weight: .semibold))
            .tracking(0.4)
            .foregroundStyle(fg)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(bg))
            .shadow(color: .black.opacity(0.15), radius: 0, x: -2, y: 2)
            .rotationEffect(.degrees(angle))
    }

    // MARK: - New Game Button

    private var newGameButton: some View {
        Button(action: onNewGame) {
            Text("New game")
                .font(.roobert(24, weight: .regular))
        }
        .buttonStyle(PlayfulPillButtonStyle(
            background: .lemon500,
            foreground: .ink,
            shadowOffset: 8
        ))
    }
}

#Preview("Light") {
    HomeView()
}

#Preview("Dark") {
    HomeView()
        .preferredColorScheme(.dark)
}
