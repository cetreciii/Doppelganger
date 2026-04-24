import SwiftUI
import MultipeerConnectivity
internal import Combine

struct VotingView: View {
    @ObservedObject var manager: MultipeerManager
    let onReveal: () -> Void

    // Local vote state
    @State private var starVotes: [String: Int] = [:]       // targetName → stars
    @State private var aiVote: String? = nil
    @State private var pretenderVote: String? = nil
    @State private var votingDone = false
    @State private var timeRemaining: Int = 0

    private var myName: String { manager.myPeerID.displayName }
    private var stories: [PlayerStory] { manager.allStories }
    private var votingTime: Int { manager.settings.votingTime }

    private var isLoading: Bool { stories.isEmpty }

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

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
        .onAppear { timeRemaining = votingTime }
        .onReceive(ticker) { _ in
            guard !votingDone else { return }
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else if !votingDone {
                submitAllVotes()
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { votingDone = true }
                manager.markVotingComplete()
            }
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
                .padding(.horizontal, 32)
                .padding(.top, 24)
                .padding(.bottom, 48)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            timerRing
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

    private var timerRing: some View {
        let fraction = Double(timeRemaining) / Double(max(votingTime, 1))
        let ringColor: Color = fraction > 0.5 ? .matcha300 : fraction > 0.2 ? .lemon500 : .pomegranate400
        return ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 112, height: 112)
                .shadow(color: .black.opacity(0.22), radius: 8, x: -3, y: 3)
            Circle()
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 5]))
                .foregroundStyle(Color.oatBorder)
                .frame(width: 112, height: 112)
            Circle()
                .stroke(Color.oatLight, lineWidth: 5)
                .frame(width: 82, height: 82)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(ringColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .frame(width: 82, height: 82)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: timeRemaining)
            VStack(spacing: 1) {
                Text("\(timeRemaining)")
                    .font(.roobert(30, weight: .semibold))
                    .foregroundStyle(Color.ink)
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.linear(duration: 0.3), value: timeRemaining)
                Text("sec")
                    .font(.roobert(11, weight: .medium))
                    .tracking(0.5)
                    .foregroundStyle(Color.warmSilver)
            }
        }
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
        guard let ai = aiVote, let pretender = pretenderVote else { return }
        let unvotedStories = stories.filter {
            $0.playerName != ai && $0.playerName != pretender && $0.playerName != myName
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

    @State private var showingStarPicker = false
    @State private var hoveredStar: Int = 1
    @State private var pressStartTime: Date? = nil

    @State private var cardRotation: Double = Double.random(in: -3.5...3.5)

    private var accentColor: Color {
        if isAIVoted { return .slushie500 }
        if isPretenderVoted { return .ube300 }
        return .white
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            storyText
            Divider()
                .background(Color.white.opacity(0.2))
                .padding(.horizontal, 16)
            voteButtons
        }
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.ube800)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: -4, y: 4)
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.black, lineWidth: 2)
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                    .foregroundStyle(accentColor)
            }
        )
        .overlay(alignment: .bottom) {
            if showingStarPicker {
                starPicker
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(.scale(scale: 0.85, anchor: .bottom).combined(with: .opacity))
            }
        }
        .rotationEffect(.degrees(cardRotation))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isAIVoted)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPretenderVoted)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showingStarPicker)
        .onChange(of: isAIVoted) { _, v in if v { showingStarPicker = false } }
        .onChange(of: isPretenderVoted) { _, v in if v { showingStarPicker = false } }
    }

    private var storyText: some View {
        Text(story.story)
            .font(.roobert(16))
            .foregroundStyle(Color.white)
            .lineSpacing(4)
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var voteButtons: some View {
        HStack(spacing: 8) {
            // Human star button — long press to open picker, drag to select, release to confirm
            HStack(spacing: 4) {
                Image(systemName: starVotes > 0 ? "star.fill" : "star")
                    .font(.system(size: 13))
                Text(starVotes > 0 ? "\(starVotes)" : "Human")
                    .font(.roobert(13, weight: .semibold))
            }
            .foregroundStyle(starVotes > 0 ? Color.lemon700 : (!isAIVoted && !isPretenderVoted ? Color.warmCharcoal : Color.warmCharcoal.opacity(0.4)))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(starVotes > 0 ? Color.lemon400 : Color.oatLight)
                    .shadow(color: .black, radius: 0, x: -3, y: 3)
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        guard !isAIVoted && !isPretenderVoted else { return }
                        if pressStartTime == nil { pressStartTime = Date() }
                        let elapsed = Date().timeIntervalSince(pressStartTime ?? Date())
                        if elapsed >= 0.2 && !showingStarPicker {
                            hoveredStar = max(1, starVotes)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { showingStarPicker = true }
                        }
                        if showingStarPicker {
                            hoveredStar = max(1, min(6, 1 + Int(max(0, value.translation.width) / 44)))
                        }
                    }
                    .onEnded { _ in
                        pressStartTime = nil
                        if showingStarPicker {
                            onStarVote(hoveredStar)
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { showingStarPicker = false }
                        }
                    }
            )

            voteButton("AI", color: .slushie500, textColor: .ink, isSelected: isAIVoted, action: onAIVote)
            voteButton("Pretender", color: .ube300, textColor: .ube800, isSelected: isPretenderVoted, action: onPretenderVote)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }

    private var starPicker: some View {
        HStack(spacing: 0) {
            ForEach(1...6, id: \.self) { i in
                Image(systemName: i <= hoveredStar ? "star.fill" : "star")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(i <= hoveredStar ? Color.lemon500 : Color.oatBorder)
                    .scaleEffect(i <= hoveredStar ? 1.15 : 1.0)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .animation(.spring(response: 0.15, dampingFraction: 0.6), value: hoveredStar)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: .black, radius: 0, x: -4, y: 4)
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.oatBorder, lineWidth: 1))
        )
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


#Preview {
    VotingView(manager: MultipeerManager(), onReveal: {})
}
