import SwiftUI

enum AppScreen {
    case home, lobbyChoice, createLobby, joinLobby
}

struct ContentView: View {
    @StateObject private var manager = MultipeerManager()
    @State private var screen: AppScreen = .home

    var body: some View {
        Group {
            switch screen {
            case .home:
                HomeView {
                    screen = .lobbyChoice
                }
            case .lobbyChoice:
                LobbyView(
                    onCreateLobby: { screen = .createLobby },
                    onJoinLobby: { screen = .joinLobby },
                    onBack: { screen = .home }
                )
            case .createLobby:
                CreateLobbyView(manager: manager) {
                    manager.reset()
                    screen = .lobbyChoice
                }
            case .joinLobby:
                JoinLobbyView(manager: manager) {
                    manager.reset()
                    screen = .lobbyChoice
                }
            }
        }
        .onChange(of: manager.gameStarted) { _, started in
            if started {
                // TODO: navigate to role assignment screen
            }
        }
    }
}

#Preview {
    ContentView()
}
