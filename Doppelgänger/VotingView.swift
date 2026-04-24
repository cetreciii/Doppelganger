import SwiftUI
import MultipeerConnectivity

struct VotingView: View {
    @ObservedObject var manager: MultipeerManager
    let onReveal: () -> Void

    // Local vote state
    @State private var starVotes: [String: Int] = [:]       // targetName → stars
    @State private var aiVote: String? = nil
    @State private var pretenderVote: String? = nil
    @State private var votingDone = false

    private var myName: String { manager.myPeerID.displayName }
    private var stories: [PlayerStory] { manager.allStories }

    private var isLoading: Bool { stories.isEmpty }

    var body: some View {
        ZStack {
            Color.canvas.ignoresSafeArea()
            if isLoading {
                loadingView
            } else {
                mainContent
            }
            if votingDone {
                waitingOverlay
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: votingDone)
        .onChange(of: manager.revealPhase) { _, reveal in
            if reveal { onReveal() }
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 16) {
            Text("Collecting stories…")
                .font(.roobert(22, weight: .semibold))
                .foregroundStyle(Color.ink)
            Text("The AI is writing its story.")
                .font(.roobert(16))
                .foregroundStyle(Color.warmSilver)
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(stories) { story in
                        StoryVoteCard(
                            story: story,
                            starVotes: starVotes[story.playerName] ?? 0,
                            isAIVoted: aiVote == story.playerName,
                            isPretenderVoted: pretenderVote == story.playerName,
                            onStarVote: { stars in handleStarVote(story: story, stars: stars) },
                            onAIVote: { handleAIVote(story: story) },
                            onPretenderVote: { handlePretenderVote(story: story) }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("Vote")
                .font(.roobert(38, weight: .semibold))
                .foregroundStyle(Color.ink)
                .tracking(-1.5)
            Text("Who's the AI? Who's the Pretender?")
                .font(.roobert(14))
                .foregroundStyle(Color.warmSilver)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
        .padding(.bottom, 20)
    }

    // MARK: - Waiting Overlay

    private var waitingOverlay: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 0) {
                Text("Votes submitted!")
                    .font(.roobert(28, weight: .semibold))
                    .foregroundStyle(Color.ink)
                    .tracking(-1)
                    .padding(.bottom, 6)
                Text("Waiting for everyone…")
                    .font(.roobert(15))
                    .foregroundStyle(Color.warmSilver)
                    .padding(.bottom, 28)

                VStack(spacing: 10) {
                    ForEach(manager.allPlayerNames, id: \.self) { name in
                        let done = manager.completedVoters.contains(name)
                        HStack {
                            Text(name)
                                .font(.roobert(16, weight: .medium))
                                .foregroundStyle(Color.ink)
                            Spacer()
                            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(done ? Color.matcha600 : Color.oatBorder)
                                .font(.system(size: 20))
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white)
                        )
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: done)
                    }
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.canvas)
                    .shadow(color: .black, radius: 0, x: -7, y: 7)
            )
            .padding(.horizontal, 28)
        }
    }

    // MARK: - Vote Logic

    private func handleStarVote(story: PlayerStory, stars: Int) {
        guard aiVote != story.playerName else { return }
        starVotes[story.playerName] = stars
        checkVotingComplete()
    }

    private func handleAIVote(story: PlayerStory) {
        if aiVote == story.playerName {
            aiVote = nil
        } else {
            aiVote = story.playerName
        }
        starVotes.removeValue(forKey: story.playerName)
        checkVotingComplete()
    }

    private func handlePretenderVote(story: PlayerStory) {
        if pretenderVote == story.playerName {
            pretenderVote = nil
        } else {
            pretenderVote = story.playerName
        }
        checkVotingComplete()
    }

    private func checkVotingComplete() {
        guard let ai = aiVote, let _ = pretenderVote else { return }
        // Every non-self, non-AI story must be star-rated (pretender story included)
        let unvotedStories = stories.filter {
            $0.playerName != ai && $0.playerName != myName
        }
        let allStarred = unvotedStories.allSatisfy { (starVotes[$0.playerName] ?? 0) > 0 }
        guard allStarred, !votingDone else { return }

        submitAllVotes()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { votingDone = true }
        manager.markVotingComplete()
    }

    private func submitAllVotes() {
        if let ai = aiVote {
            manager.submitVote(GameVote(voterName: myName, targetName: ai, stars: 0, voteType: .ai))
        }
        if let pretender = pretenderVote {
            manager.submitVote(GameVote(voterName: myName, targetName: pretender, stars: 0, voteType: .pretender))
        }
        for (target, stars) in starVotes {
            manager.submitVote(GameVote(voterName: myName, targetName: target, stars: stars, voteType: .stars))
        }
    }
}

// MARK: - Story Vote Card

struct StoryVoteCard: View {
    let story: PlayerStory
    let starVotes: Int
    let isAIVoted: Bool
    let isPretenderVoted: Bool
    let onStarVote: (Int) -> Void
    let onAIVote: () -> Void
    let onPretenderVote: () -> Void

    private var tintColor: Color? {
        if isAIVoted { return .slushie500 }
        if isPretenderVoted { return .ube300 }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            storyText
            Divider()
                .background(Color.oatBorder)
                .padding(.horizontal, 16)
            voteButtons
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(tintColor?.opacity(0.18) ?? Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(tintColor ?? Color.oatBorder, lineWidth: tintColor != nil ? 2 : 1)
                )
        )
        .shadow(color: .black.opacity(0.12), radius: 0, x: -5, y: 5)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isAIVoted)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPretenderVoted)
    }

    private var storyText: some View {
        Text(story.story)
            .font(.roobert(16))
            .foregroundStyle(Color.ink)
            .lineSpacing(4)
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var voteButtons: some View {
        HStack(spacing: 8) {
            StarVoteButton(currentStars: starVotes, isActive: !isAIVoted, onVote: onStarVote)
            voteButton("AI", color: .slushie500, textColor: .ink, isSelected: isAIVoted, action: onAIVote)
            voteButton("Pretender", color: .ube300, textColor: .ube800, isSelected: isPretenderVoted, action: onPretenderVote)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }

    private func voteButton(_ label: String, color: Color, textColor: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.roobert(13, weight: .semibold))
                .foregroundStyle(isSelected ? textColor : Color.warmCharcoal)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? color : Color.oatLight)
                        .shadow(color: .black, radius: 0, x: isSelected ? -2 : -3, y: isSelected ? 2 : 3)
                )
                .offset(x: isSelected ? -1 : 0, y: isSelected ? 1 : 0)
        }
        .animation(.spring(response: 0.2, dampingFraction: 0.55), value: isSelected)
    }
}

// MARK: - Star Vote Button

struct StarVoteButton: View {
    let currentStars: Int
    let isActive: Bool
    let onVote: (Int) -> Void

    @State private var showingStars = false
    @State private var selectedStars: Int = 1
    @State private var pressStartTime: Date? = nil
    @State private var starScale: [CGFloat] = Array(repeating: 0, count: 6)

    var body: some View {
        ZStack(alignment: .bottom) {
            buttonFace
            if showingStars { starPicker }
        }
    }

    private var buttonFace: some View {
        HStack(spacing: 4) {
            Image(systemName: currentStars > 0 ? "star.fill" : "star")
                .font(.system(size: 13))
            Text(currentStars > 0 ? "\(currentStars)" : "Human")
                .font(.roobert(13, weight: .semibold))
        }
        .foregroundStyle(currentStars > 0 ? Color.lemon700 : (isActive ? Color.warmCharcoal : Color.oatBorder))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(currentStars > 0 ? Color.lemon400 : Color.oatLight)
                .shadow(color: .black, radius: 0, x: -3, y: 3)
        )
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { val in
                    guard isActive else { return }
                    if pressStartTime == nil { pressStartTime = Date() }
                    let elapsed = Date().timeIntervalSince(pressStartTime ?? Date())
                    if elapsed >= 0.35 && !showingStars {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { showingStars = true }
                        for i in 0..<6 {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.55).delay(Double(i) * 0.05)) {
                                starScale[i] = 1
                            }
                        }
                    }
                    if showingStars {
                        let x = val.translation.width
                        selectedStars = max(1, min(6, 1 + Int(x / 36)))
                    }
                }
                .onEnded { _ in
                    if showingStars {
                        onVote(selectedStars)
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { showingStars = false }
                        starScale = Array(repeating: 0, count: 6)
                    }
                    pressStartTime = nil
                }
        )
        .allowsHitTesting(isActive)
    }

    private var starPicker: some View {
        HStack(spacing: 6) {
            ForEach(0..<6, id: \.self) { i in
                Image(systemName: i < selectedStars ? "star.fill" : "star")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(i < selectedStars ? Color.lemon500 : Color.oatBorder)
                    .scaleEffect(starScale[i])
                    .scaleEffect(i < selectedStars ? 1.15 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.5), value: selectedStars)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: .black, radius: 0, x: -4, y: 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.oatBorder, lineWidth: 1)
                )
        )
        .offset(y: -54)
        .transition(.scale(scale: 0.7, anchor: .bottom).combined(with: .opacity))
    }
}

#Preview {
    VotingView(manager: MultipeerManager(), onReveal: {})
}
