import SwiftUI

enum AppScreen {
    case home, createLobby, joinLobby
}

struct ContentView: View {
    @StateObject private var manager = MultipeerManager()
    @State private var screen: AppScreen = .home

    var body: some View {
        Group {
            switch screen {
            case .home:
                HomeView(
                    onCreateLobby: { screen = .createLobby },
                    onJoinLobby: { screen = .joinLobby }
                )
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
