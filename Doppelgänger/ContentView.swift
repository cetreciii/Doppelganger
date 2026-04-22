import SwiftUI
import MultipeerConnectivity

enum AppScreen {
    case home, createLobby, joinLobby, game
}

struct ContentView: View {
    @StateObject private var manager = MultipeerManager()
    @State private var screen: AppScreen = .home
    @State private var playerName: String = ""
    @State private var showNameError: Bool = false

    var body: some View {
        Group {
            switch screen {
            case .home:
                HomeView(
                    onCreateLobby: { name in
                        if name.trimmingCharacters(in: .whitespaces).isEmpty {
                            showNameError = true
                        } else {
                            playerName = name
                            manager.myPeerID = MCPeerID(displayName: name)
                            screen = .createLobby
                        }
                    },
                    onJoinLobby: { name in
                        if name.trimmingCharacters(in: .whitespaces).isEmpty {
                            showNameError = true
                        } else {
                            playerName = name
                            manager.myPeerID = MCPeerID(displayName: name)
                            screen = .joinLobby
                        }
                    }
                )
                .alert("Please enter your name", isPresented: $showNameError) {
                    Button("OK") { }
                }
            case .createLobby:
                CreateLobbyView(manager: manager) {
                    manager.reset()
                    screen = .home
                }
            case .joinLobby:
                JoinLobbyView(manager: manager) {
                    manager.reset()
                    screen = .home
                }
            case .game:
                GameView(manager: manager) {
                    manager.reset()
                    screen = .home
                }
            }
        }
        .onChange(of: manager.gameStarted) { _, started in
            if started {
                screen = .game
            }
        }
    }
}

#Preview {
    ContentView()
}
