import SwiftUI
import MultipeerConnectivity

struct JoinLobbyView: View {
    @ObservedObject var manager: MultipeerManager
    let onBack: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }
    private var bgColor: Color { isLight ? .canvas : .ube900 }
    private var textColor: Color { isLight ? .ink : .white }
    private var cardBg: Color { isLight ? .white : .ube800 }
    private var borderColor: Color { isLight ? .oatBorder : .darkBorder }
    private var secondaryText: Color { isLight ? .warmSilver : .ube300 }

    private var isJoined: Bool { !manager.connectedPeers.isEmpty }

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 24)
                    .padding(.top, 60)

                if isJoined {
                    waitingRoom
                } else {
                    browseView
                }
            }
        }
        .onAppear {
            manager.startBrowsing()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
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
            if isJoined {
                Text("In lobby")
                    .font(.roobert(13, weight: .semibold))
                    .tracking(0.6)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.matcha600)
            }
        }
        .padding(.bottom, 32)
    }

    // MARK: - Browse

    private var browseView: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                Text("Join a lobby")
                    .font(.roobert(44, weight: .semibold))
                    .tracking(-1.8)
                    .foregroundStyle(textColor)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Lobbies on your local network will appear below.")
                    .font(.roobert(16))
                    .foregroundStyle(secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 24)

            Spacer().frame(height: 36)

            if manager.discoveredLobbies.isEmpty {
                emptyState
                    .padding(.horizontal, 24)
            } else {
                lobbyList
                    .padding(.horizontal, 24)
            }

            Spacer()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(secondaryText)
                .scaleEffect(1.2)
            Text("Looking for lobbies nearby…")
                .font(.roobert(16))
                .foregroundStyle(secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    private var lobbyList: some View {
        VStack(spacing: 12) {
            ForEach(manager.discoveredLobbies) { lobby in
                lobbyCard(lobby)
            }
        }
    }

    private func lobbyCard(_ lobby: DiscoveredLobby) -> some View {
        Button {
            manager.joinLobby(lobby)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(lobby.hostName)
                        .font(.roobert(18, weight: .semibold))
                        .foregroundStyle(textColor)
                    Text("Host")
                        .font(.roobert(13))
                        .foregroundStyle(secondaryText)
                }
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(secondaryText)
            }
            .padding(20)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(cardBg)
                        .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 1)
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(borderColor.opacity(0.5), lineWidth: 1)
                }
            )
        }
    }

    // MARK: - Waiting Room

    private var waitingRoom: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                waitingHeader
                settingsPreview
                playersSection
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    private var waitingHeader: some View {
        VStack(spacing: 8) {
            Text("You're in!")
                .font(.roobert(44, weight: .semibold))
                .tracking(-1.8)
                .foregroundStyle(textColor)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Waiting for the host to start the game.")
                .font(.roobert(16))
                .foregroundStyle(secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var settingsPreview: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Game settings")
                .font(.roobert(13, weight: .semibold))
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundStyle(secondaryText)

            HStack(spacing: 8) {
                settingsBadge(label: "\(manager.settings.numberOfAI) AI", color: .ube800)
                settingsBadge(label: "\(manager.settings.numberOfPretenders) Pretender\(manager.settings.numberOfPretenders > 1 ? "s" : "")", color: .pomegranate400)
                settingsBadge(label: "Write \(formatTime(manager.settings.writingTime))", color: .slushie800)
                settingsBadge(label: "Vote \(formatTime(manager.settings.votingTime))", color: .matcha600)
            }
            .flexibleFrame()
        }
    }

    private func settingsBadge(label: String, color: Color) -> some View {
        Text(label)
            .font(.roobert(12, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Capsule().fill(color))
    }

    private var playersSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Players")
                    .font(.roobert(13, weight: .semibold))
                    .tracking(0.6)
                    .textCase(.uppercase)
                    .foregroundStyle(secondaryText)
                Spacer()
                Text("\(manager.allPlayerNames.count)")
                    .font(.roobert(13, weight: .semibold))
                    .foregroundStyle(secondaryText)
            }

            if manager.allPlayerNames.isEmpty {
                HStack(spacing: 10) {
                    ProgressView().tint(secondaryText)
                    Text("Loading players…")
                        .font(.roobert(15))
                        .foregroundStyle(secondaryText)
                }
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(manager.allPlayerNames, id: \.self) { name in
                        playerChip(name, isYou: name == manager.myPeerID.displayName)
                    }
                }
            }
        }
    }

    private func playerChip(_ name: String, isYou: Bool) -> some View {
        HStack(spacing: 5) {
            if isYou {
                Circle()
                    .fill(Color.lemon500)
                    .frame(width: 6, height: 6)
            }
            Text(isYou ? "\(name) (you)" : name)
                .font(.roobert(13, weight: isYou ? .semibold : .regular))
                .foregroundStyle(isYou ? textColor : secondaryText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(isYou
                    ? (isLight ? Color.lemon400.opacity(0.3) : Color.lemon500.opacity(0.2))
                    : (isLight ? Color.oatLight : Color(hex: "3a1480")))
        )
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: Int) -> String {
        seconds < 60 ? "\(seconds)s" : "\(seconds / 60)m"
    }
}

private extension View {
    func flexibleFrame() -> some View {
        self.frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("Browse — Light") {
    JoinLobbyView(manager: MultipeerManager(), onBack: {})
}
#Preview("Browse — Dark") {
    JoinLobbyView(manager: MultipeerManager(), onBack: {})
        .preferredColorScheme(.dark)
}
