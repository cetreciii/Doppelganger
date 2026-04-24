import MultipeerConnectivity
import SwiftUI
import UIKit
import FoundationModels
internal import Combine

// MARK: - Models

struct GameSettings: Codable, Equatable {
    var numberOfAI: Int = 1
    var numberOfPretenders: Int = 1
    var writingTime: Int = 1
    var votingTime: Int = 120
}

enum PlayerRole: String, Codable {
    case human, ai, pretender
}

struct PlayerStory: Codable, Identifiable, Equatable {
    let playerName: String
    let story: String
    let role: PlayerRole
    var id: String { playerName }
}

struct GameVote: Codable, Equatable {
    let voterName: String
    let targetName: String
    let stars: Int
    let voteType: VoteType
    enum VoteType: String, Codable { case stars, ai, pretender }
}

private enum LobbyMessage: Codable {
    case settingsUpdated(GameSettings)
    case playerListUpdated([String])
    case startGame
    case rolesAssigned(roles: [String: String])
    case gameReady(roles: [String: String], words: [String])
    case storySubmitted(playerName: String, story: String)
    case storiesReady([PlayerStory])
    case voteSubmitted(GameVote)
    case voterDone(playerName: String)
    case allVotesIn
}

struct DiscoveredLobby: Identifiable {
    let peer: MCPeerID
    var id: String { peer.displayName }
    var hostName: String { peer.displayName }
}

// MARK: - Manager

class MultipeerManager: NSObject, ObservableObject {
    private static let serviceType = "doppelganger"

    @Published var myPeerID: MCPeerID {
        didSet {
            session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
            session.delegate = self
        }
    }
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

    // Voting phase
    @Published var myRole: PlayerRole = .human
    @Published var myRoleAssigned: Bool = false
    @Published var assignedRoles: [String: PlayerRole] = [:]
    @Published var allStories: [PlayerStory] = []
    @Published var votes: [GameVote] = []
    @Published var completedVoters: Set<String> = []
    @Published var votingPhase: Bool = false
    @Published var revealPhase: Bool = false

    private var receivedStories: [PlayerStory] = []
    private var wordGenerationTask: Task<[String], Never>?

    override init() {
        let initialPeerID = MCPeerID(displayName: UIDevice.current.name)
        myPeerID = initialPeerID
        session = MCSession(peer: initialPeerID, securityIdentity: nil, encryptionPreference: .required)
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

    func broadcastRoles() {
        var roles: [String: PlayerRole] = [:]
        let shuffled = allPlayerNames.shuffled()
        for i in 0..<min(settings.numberOfPretenders, shuffled.count) {
            roles[shuffled[i]] = .pretender
        }
        for name in shuffled.dropFirst(settings.numberOfPretenders) {
            roles[name] = .human
        }
        assignedRoles = roles
        myRole = roles[myPeerID.displayName] ?? .human
        myRoleAssigned = true
        if !connectedPeers.isEmpty {
            send(.rolesAssigned(roles: roles.mapValues { $0.rawValue }), to: connectedPeers)
        }
    }

    func beginWordGeneration() {
        wordGenerationTask = Task { await generateWords() }
    }

    func broadcastWords() async {
        let words: [String]
        if let task = wordGenerationTask {
            words = await task.value
        } else {
            words = await generateWords()
        }
        await MainActor.run { gameWords = words }
        let rolesDict = assignedRoles.mapValues { $0.rawValue }
        if !connectedPeers.isEmpty { send(.gameReady(roles: rolesDict, words: words), to: connectedPeers) }
    }

    private func generateWords() async -> [String] {
        if #available(iOS 26.0, macOS 26.0, *), SystemLanguageModel.default.isAvailable {
            do {
                let session = LanguageModelSession()
                let response = try await session.respond(
                    to: "Give me exactly 3 unrelated, imaginative nouns for a creative writing prompt. Reply with only the 3 words separated by commas, lowercase, no punctuation, no explanation."
                )
                let raw = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
                let parsed = raw.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
                if parsed.count >= 3 { return Array(parsed.prefix(3)) }
            } catch {}
        }
        return fallbackWords()
    }

    private func fallbackWords() -> [String] {
        let pool = [
            ["lighthouse", "mirror", "clockwork"],
            ["fog", "compass", "cathedral"],
            ["echo", "lantern", "telescope"],
            ["thunder", "cellar", "marionette"],
            ["glacier", "riddle", "mercury"],
        ]
        return pool.randomElement()!
    }

    func submitMyStory(_ story: String) {
        let name = myPeerID.displayName
        if isHost {
            hostReceiveStory(PlayerStory(playerName: name, story: story, role: assignedRoles[name] ?? .human))
        } else {
            send(.storySubmitted(playerName: name, story: story), to: connectedPeers)
        }
    }

    func submitVote(_ vote: GameVote) {
        votes.append(vote)
        send(.voteSubmitted(vote), to: connectedPeers)
    }

    func markVotingComplete() {
        let name = myPeerID.displayName
        completedVoters.insert(name)
        send(.voterDone(playerName: name), to: connectedPeers)
        if isHost { checkAllVoted() }
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
        myRole = .human
        myRoleAssigned = false
        assignedRoles = [:]
        wordGenerationTask?.cancel()
        wordGenerationTask = nil
        allStories = []
        votes = []
        completedVoters = []
        votingPhase = false
        revealPhase = false
        receivedStories = []
    }

    // MARK: Private

    private func send(_ message: LobbyMessage, to peers: [MCPeerID]) {
        guard !peers.isEmpty, let data = try? JSONEncoder().encode(message) else { return }
        try? session.send(data, toPeers: peers, with: .reliable)
    }

    private func hostReceiveStory(_ story: PlayerStory) {
        guard !receivedStories.contains(where: { $0.playerName == story.playerName }) else { return }
        receivedStories.append(story)
        if receivedStories.count == allPlayerNames.count {
            Task { await hostGenerateAndBroadcastStories() }
        }
    }

    private func hostGenerateAndBroadcastStories() async {
        var stories = receivedStories
        for i in 0..<settings.numberOfAI {
            let aiName = settings.numberOfAI > 1 ? "AI \(i + 1)" : "AI"
            let aiStory = await generateAIStory(words: gameWords)
            stories.append(PlayerStory(playerName: aiName, story: aiStory, role: .ai))
        }
        stories.shuffle()
        await MainActor.run {
            allStories = stories
            votingPhase = true
            if !connectedPeers.isEmpty { send(.storiesReady(stories), to: connectedPeers) }
        }
    }

    private func generateAIStory(words: [String]) async -> String {
        if #available(iOS 26.0, macOS 26.0, *), SystemLanguageModel.default.isAvailable {
            do {
                let session = LanguageModelSession()
                let prompt = "Write a short creative story (3-4 sentences) that naturally incorporates these three words: \(words.joined(separator: ", ")). Write in first person, concise and imaginative."
                let response = try await session.respond(to: prompt)
                return response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            } catch {}
        }
        return "The \(words.first ?? "light") flickered as I reached for the \(words.dropFirst().first ?? "key"), wondering if the \(words.last ?? "door") would ever open again."
    }

    private func checkAllVoted() {
        guard completedVoters.count == allPlayerNames.count else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self else { return }
            self.revealPhase = true
            self.send(.allVotesIn, to: self.connectedPeers)
        }
    }
}

// MARK: - MCSessionDelegate

extension MultipeerManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            switch state {
            case .connected:
                if !self.connectedPeers.contains(peerID) { self.connectedPeers.append(peerID) }
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
            default: break
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
            case .rolesAssigned(let rolesDict):
                let roles = rolesDict.compactMapValues { PlayerRole(rawValue: $0) }
                self.assignedRoles = roles
                self.myRole = roles[self.myPeerID.displayName] ?? .human
                self.myRoleAssigned = true
            case .gameReady(let rolesDict, let words):
                self.gameWords = words
                let roles = rolesDict.compactMapValues { PlayerRole(rawValue: $0) }
                self.assignedRoles = roles
                self.myRole = roles[self.myPeerID.displayName] ?? .human
            case .storySubmitted(let name, let story):
                if self.isHost {
                    let role = self.assignedRoles[name] ?? .human
                    self.hostReceiveStory(PlayerStory(playerName: name, story: story, role: role))
                }
            case .storiesReady(let stories):
                self.allStories = stories
                self.votingPhase = true
            case .voteSubmitted(let vote):
                if !self.votes.contains(vote) {
                    self.votes.append(vote)
                    if self.isHost { self.send(.voteSubmitted(vote), to: self.connectedPeers) }
                }
            case .voterDone(let name):
                self.completedVoters.insert(name)
                if self.isHost { self.checkAllVoted() }
            case .allVotesIn:
                self.revealPhase = true
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
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {}
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
        DispatchQueue.main.async { [weak self] in self?.discoveredLobbies.removeAll { $0.peer == peerID } }
    }
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {}
}
