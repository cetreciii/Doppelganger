import SwiftUI

struct HomeView: View {
    var onCreateLobby: (String) -> Void = { _ in }
    var onJoinLobby: (String) -> Void = { _ in }

    @State private var playerName: String = ""

    @Environment(\.colorScheme) private var colorScheme

    private var isLight: Bool { colorScheme == .light }

    private var backgroundColor: Color { isLight ? .canvas : .ube900 }
    private var textColor: Color { isLight ? .ink : .white }
    private var cardBackground: Color { isLight ? .white : .ube800 }
    private var borderColor: Color { isLight ? .oatBorder : .darkBorder }

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

                Spacer()

                gameButtons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 52)
            }
        }
    }

    // MARK: - Title Card

    private var titleCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.ube800)
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 1)
                .shadow(color: .black.opacity(0.05), radius: 0, x: 0, y: -1)

            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(style: StrokeStyle(lineWidth: 5))
                .foregroundStyle(.black)

            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(style: StrokeStyle(lineWidth: 5, dash: [5, 5]))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 8) {

                Text("Doppel\u{00AD}gänger")
                    .font(.roobert(50, weight: .semibold))
                    .tracking(-2.4)
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
            
            VStack(alignment: .leading, spacing: 8) {
                Spacer()
                HStack(spacing: 0) {
                    Text("Hello, my name is ")
                        .font(.roobert(14, weight: .regular))
                        .foregroundStyle(.white)
                    TextField("", text: $playerName, prompt: Text("_____________").foregroundColor(Color(hex: "999999")))
                        .font(.roobert(14, weight: .regular))
                        .foregroundStyle(.white)
                }
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

    // MARK: - Game Buttons

    private var gameButtons: some View {
        VStack(spacing: 14) {
            Button(action: { onCreateLobby(playerName) }) {
                Text("Create lobby")
                    .font(.roobert(24, weight: .regular))
            }
            .buttonStyle(PlayfulPillButtonStyle(
                background: .lemon500,
                foreground: .ink,
                shadowOffset: 8
            ))

            Button(action: { onJoinLobby(playerName) }) {
                Text("Join lobby")
                    .font(.roobert(24, weight: .regular))
            }
            .buttonStyle(PlayfulPillButtonStyle(
                background: .slushie500,
                foreground: .ink,
                shadowOffset: 8
            ))
        }
    }
}

#Preview("Light") {
    HomeView()
}

#Preview("Dark") {
    HomeView()
        .preferredColorScheme(.dark)
}
