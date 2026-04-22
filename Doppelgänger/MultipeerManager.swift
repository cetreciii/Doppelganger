import MultipeerConnectivity
import SwiftUI
import UIKit
internal import Combine

// MARK: - Models

struct GameSettings: Codable, Equatable {
    var numberOfAI: Int = 1
    var numberOfPretenders: Int = 1
    var writingTime: Int = 60   // seconds: 60, 90, 120
    var votingTime: Int = 120   // seconds: 60, 120, 180
}

private enum LobbyMessage: Codable {
    case settingsUpdated(GameSettings)
    case playerListUpdated([String])
    case startGame
    case wordsReady([String])
}

struct DiscoveredLobby: Identifiable {
    let peer: MCPeerID
    var id: String { peer.displayName }
    var hostName: String { peer.displayName }
}

// MARK: - Manager

class MultipeerManager: NSObject, ObservableObject {
    private static let serviceType = "doppelganger"

    let myPeerID: MCPeerID
    private var session: MCSession
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?

    @Published var connectedPeers: [MCPeerID] = []
    @Published var discoveredLobbies: [DiscoveredLobby] = []
    @Published var settings: GameSettings = GameSettings()
    @Published var allPlayerNames: [String] = []
    @Published var isHost: Bool = false
    @Published var gameStarted: Bool = false
    @Published var gameWords: [String] = []

    override init() {
        myPeerID = MCPeerID(displayName: UIDevice.current.name)
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        super.init()
        session.delegate = self
    }

    // MARK: Host

    func startHosting() {
        isHost = true
        allPlayerNames = [myPeerID.displayName]
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: Self.serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
    }

    func updateSettings(_ newSettings: GameSettings) {
        settings = newSettings
        guard !connectedPeers.isEmpty else { return }
        send(.settingsUpdated(newSettings), to: connectedPeers)
    }

    func startGame() {
        send(.startGame, to: connectedPeers)
        gameStarted = true
    }

    func broadcastWords(_ words: [String]) {
        gameWords = words
        guard !connectedPeers.isEmpty else { return }
        send(.wordsReady(words), to: connectedPeers)
    }

    // MARK: Joiner

    func startBrowsing() {
        isHost = false
        browser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: Self.serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
    }

    func joinLobby(_ lobby: DiscoveredLobby) {
        browser?.invitePeer(lobby.peer, to: session, withContext: nil, timeout: 15)
    }

    // MARK: Shared

    func reset() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        session.disconnect()
        advertiser = nil
        browser = nil
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        connectedPeers = []
        discoveredLobbies = []
        settings = GameSettings()
        allPlayerNames = []
        isHost = false
        gameStarted = false
        gameWords = []
    }

    // MARK: Private

    private func send(_ message: LobbyMessage, to peers: [MCPeerID]) {
        guard !peers.isEmpty, let data = try? JSONEncoder().encode(message) else { return }
        try? session.send(data, toPeers: peers, with: .reliable)
    }
}

// MARK: - MCSessionDelegate

extension MultipeerManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            switch state {
            case .connected:
                if !self.connectedPeers.contains(peerID) {
                    self.connectedPeers.append(peerID)
                }
                if self.isHost {
                    if !self.allPlayerNames.contains(peerID.displayName) {
                        self.allPlayerNames.append(peerID.displayName)
                    }
                    self.send(.settingsUpdated(self.settings), to: [peerID])
                    self.send(.playerListUpdated(self.allPlayerNames), to: self.connectedPeers)
                }
            case .notConnected:
                self.connectedPeers.removeAll { $0 == peerID }
                if self.isHost {
                    self.allPlayerNames.removeAll { $0 == peerID.displayName }
                    if !self.connectedPeers.isEmpty {
                        self.send(.playerListUpdated(self.allPlayerNames), to: self.connectedPeers)
                    }
                }
            default:
                break
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let msg = try? JSONDecoder().decode(LobbyMessage.self, from: data) else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            switch msg {
            case .settingsUpdated(let s): self.settings = s
            case .playerListUpdated(let names): self.allPlayerNames = names
            case .startGame: self.gameStarted = true
            case .wordsReady(let w): self.gameWords = w
            }
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension MultipeerManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("[MPC] Advertiser error: \(error)")
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension MultipeerManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if !self.discoveredLobbies.contains(where: { $0.peer == peerID }) {
                self.discoveredLobbies.append(DiscoveredLobby(peer: peerID))
            }
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async { [weak self] in
            self?.discoveredLobbies.removeAll { $0.peer == peerID }
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("[MPC] Browser error: \(error)")
    }
}
