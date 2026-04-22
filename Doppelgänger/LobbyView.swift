import SwiftUI

struct LobbyView: View {
    let onCreateLobby: () -> Void
    let onJoinLobby: () -> Void
    let onBack: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }
    private var bgColor: Color { isLight ? .canvas : .ube900 }
    private var textColor: Color { isLight ? .ink : .white }
    private var secondaryText: Color { isLight ? .warmSilver : .ube300 }

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            VStack(spacing: 0) {
                backButton
                    .padding(.horizontal, 24)
                    .padding(.top, 60)

                Spacer()

                header
                    .padding(.horizontal, 24)

                Spacer().frame(height: 52)

                buttons
                    .padding(.horizontal, 24)

                Spacer()
            }
        }
    }

    // MARK: - Components

    private var backButton: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Back")
                        .font(.roobert(15, weight: .medium))
                }
                .foregroundStyle(secondaryText)
            }
            Spacer()
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Text("Play together")
                .font(.roobert(44, weight: .semibold))
                .tracking(-1.8)
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Host a new session or look for one nearby.")
                .font(.roobert(17))
                .foregroundStyle(secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var buttons: some View {
        VStack(spacing: 14) {
            Button(action: onCreateLobby) {
                Text("Create lobby")
                    .font(.roobert(22, weight: .regular))
            }
            .buttonStyle(PlayfulPillButtonStyle(
                background: .lemon500,
                foreground: .ink,
                shadowOffset: 7
            ))

            Button(action: onJoinLobby) {
                Text("Join lobby")
                    .font(.roobert(22, weight: .regular))
            }
            .buttonStyle(PlayfulPillButtonStyle(
                background: .slushie500,
                foreground: .ink,
                shadowOffset: 7
            ))
        }
    }
}

#Preview("Light") { LobbyView(onCreateLobby: {}, onJoinLobby: {}, onBack: {}) }
#Preview("Dark") { LobbyView(onCreateLobby: {}, onJoinLobby: {}, onBack: {}).preferredColorScheme(.dark) }
