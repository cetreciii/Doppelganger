import SwiftUI
import MultipeerConnectivity

struct JoinLobbyView: View {
    @ObservedObject var manager: MultipeerManager
    let onBack: () -> Void

    private var bgColor: Color { .canvas }
    private var textColor: Color { .ink }
    private var cardBg: Color { .white }
    private var borderColor: Color { .oatBorder }
    private var secondaryText: Color { .warmSilver }

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
        VStack(alignment: .leading, spacing: 0) {
            Text("Game settings")
                .font(.roobert(13, weight: .semibold))
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundStyle(secondaryText)
                .padding(.bottom, 14)

            let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
            LazyVGrid(columns: columns, spacing: 12) {
                settingStatCard(
                    value: "\(manager.settings.numberOfAI)",
                    label: "AI\(manager.settings.numberOfAI > 1 ? "s" : "") in game",
                    accent: .ube300
                )
                settingStatCard(
                    value: "\(manager.settings.numberOfPretenders)",
                    label: "Pretender\(manager.settings.numberOfPretenders > 1 ? "s" : "")",
                    accent: .pomegranate400
                )
                settingStatCard(
                    value: formatTime(manager.settings.writingTime),
                    label: "Writing time",
                    accent: .lemon500
                )
                settingStatCard(
                    value: formatTime(manager.settings.votingTime),
                    label: "Voting time",
                    accent: .matcha300
                )
            }
        }
    }

    private func settingStatCard(value: String, label: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.roobert(32, weight: .semibold))
                .foregroundStyle(textColor)
                .tracking(-0.5)
            Text(label)
                .font(.roobert(12, weight: .medium))
                .foregroundStyle(secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(accent.opacity(0.15))
        )
    }

    private var playersSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Players in lobby")
                    .font(.roobert(13, weight: .semibold))
                    .tracking(0.6)
                    .textCase(.uppercase)
                    .foregroundStyle(secondaryText)
                Spacer()
                Text("\(manager.allPlayerNames.count)")
                    .font(.roobert(13, weight: .semibold))
                    .foregroundStyle(secondaryText)
            }
            .padding(.bottom, 14)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(cardBg)
                    .shadow(color: .black.opacity(0.22), radius: 10, x: -4, y: 4)
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [14, 5]))
                    .foregroundStyle(borderColor)

                Group {
                    if manager.allPlayerNames.isEmpty {
                        HStack(spacing: 10) {
                            ProgressView().tint(secondaryText)
                            Text("Loading players…")
                                .font(.roobert(15))
                                .foregroundStyle(secondaryText)
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .topLeading)))
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(manager.allPlayerNames, id: \.self) { name in
                                playerChip(name, isYou: name == manager.myPeerID.displayName)
                                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .topLeading)))
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: manager.allPlayerNames)
                .padding(20)
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
                .fill(isYou ? Color.lemon400.opacity(0.3) : .oatLight)
        )
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: Int) -> String {
        seconds < 60 ? "\(seconds)s" : "\(seconds / 60)m"
    }
}


#Preview {
    JoinLobbyView(manager: MultipeerManager(), onBack: {})
}
