import SwiftUI

// MARK: - Results computation

private struct StoryResult {
    let story: PlayerStory
    var totalStars: Int
    var aiVoteCount: Int
    var pretenderVoteCount: Int
}

// MARK: - Reveal phase state machine

private enum RevealStep {
    case countdown(Int)
    case pretenderReveal
    case pretenderVerdict
    case aiReveal
    case aiVerdict
    case podium
}

struct ResultsView: View {
    @ObservedObject var manager: MultipeerManager
    let onDone: () -> Void

    @State private var step: RevealStep = .countdown(5)
    @State private var countdown = 5
    @State private var featuredStory: PlayerStory? = nil
    @State private var verdictVisible = false
    @State private var podiumStories: [StoryResult] = []
    @State private var podiumRevealed: Int = 0
    
    private var results: [StoryResult] {
        manager.allStories.map { story -> StoryResult in
            let name = story.playerName
            let starType = GameVote.VoteType.stars
            let aiType = GameVote.VoteType.ai
            let pretenderType = GameVote.VoteType.pretender
            let starsTotal: Int = manager.votes
                .filter { $0.targetName == name && $0.voteType == starType }
                .reduce(0) { $0 + $1.stars }
            let aiCount: Int = manager.votes
                .filter { $0.targetName == name && $0.voteType == aiType }.count
            let pretenderCount: Int = manager.votes
                .filter { $0.targetName == name && $0.voteType == pretenderType }.count
            return StoryResult(story: story, totalStars: starsTotal, aiVoteCount: aiCount, pretenderVoteCount: pretenderCount)
        }
    }

    private var humanResults: [StoryResult] {
        results.filter { $0.story.role != .ai }
            .sorted { $0.totalStars > $1.totalStars }
    }

    private var mostVotedAI: StoryResult? {
        results.max(by: { $0.aiVoteCount < $1.aiVoteCount })
    }

    private var mostVotedPretender: StoryResult? {
        results.max(by: { $0.pretenderVoteCount < $1.pretenderVoteCount })
    }

    var body: some View {
        ZStack {
            Color.canvas.ignoresSafeArea()
            Group {
                switch step {
                case .countdown(let n):
                    countdownView(n: n)
                case .pretenderReveal, .pretenderVerdict:
                    revealCard(
                        label: "Most votes for Pretender",
                        story: featuredStory,
                        verdictVisible: verdictVisible,
                        isCorrect: featuredStory?.role == .pretender,
                        correctLabel: "Pretender found!",
                        wrongLabel: "Wrong guess!"
                    )
                case .aiReveal, .aiVerdict:
                    revealCard(
                        label: "Most votes for AI",
                        story: featuredStory,
                        verdictVisible: verdictVisible,
                        isCorrect: featuredStory?.role == .ai,
                        correctLabel: "AI found!",
                        wrongLabel: "Wrong guess!"
                    )
                case .podium:
                    podiumView
                }
            }
            .transition(.asymmetric(
                insertion: .scale(scale: 0.85).combined(with: .opacity),
                removal: .opacity
            ))
            .id(stepKey)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.75), value: stepKey)
        .onAppear { startCountdown() }
    }

    private var stepKey: String {
        switch step {
        case .countdown(let n): "countdown-\(n)"
        case .pretenderReveal: "pretender-reveal"
        case .pretenderVerdict: "pretender-verdict"
        case .aiReveal: "ai-reveal"
        case .aiVerdict: "ai-verdict"
        case .podium: "podium"
        }
    }

    // MARK: - Countdown

    private func countdownView(n: Int) -> some View {
        VStack(spacing: 16) {
            Text("Revealing in…")
                .font(.roobert(18, weight: .medium))
                .foregroundStyle(Color.warmSilver)
            Text("\(n)")
                .font(.roobert(96, weight: .semibold))
                .foregroundStyle(Color.ink)
                .tracking(-4)
                .contentTransition(.numericText(countsDown: true))
                .animation(.spring(response: 0.3, dampingFraction: 0.65), value: n)
        }
    }

    // MARK: - Reveal Card

    @ViewBuilder
    private func revealCard(label: String, story: PlayerStory?, verdictVisible: Bool, isCorrect: Bool, correctLabel: String, wrongLabel: String) -> some View {
        VStack(spacing: 24) {
            Text(label)
                .font(.roobert(13, weight: .semibold))
                .tracking(0.8)
                .textCase(.uppercase)
                .foregroundStyle(Color.warmSilver)
            if let s = story {
                storyRevealCard(story: s)
                    .padding(.horizontal, 24)
            }
            if verdictVisible {
                verdictBadge(isCorrect: isCorrect, label: isCorrect ? correctLabel : wrongLabel, authorName: story?.playerName)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 80)
    }

    @ViewBuilder
    private func verdictBadge(isCorrect: Bool, label: String, authorName: String?) -> some View {
        VStack(spacing: 8) {
            Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(isCorrect ? Color.matcha300 : Color.pomegranate400)
            Text(label)
                .font(.roobert(28, weight: .semibold))
                .foregroundStyle(Color.ink)
                .tracking(-1)
            if isCorrect, let name = authorName {
                Text("Written by \(name)")
                    .font(.roobert(15))
                    .foregroundStyle(Color.warmSilver)
            }
        }
        .transition(.scale(scale: 0.5).combined(with: .opacity))
    }

    private func storyRevealCard(story: PlayerStory) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(story.story)
                .font(.roobert(17))
                .foregroundStyle(Color.white)
                .lineSpacing(4)
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
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
                    .foregroundStyle(Color.white)
            }
        )
        .rotationEffect(.degrees(cardRotation(for: story.playerName)))
    }

    private func cardRotation(for name: String) -> Double {
        let hash = name.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return (Double(hash % 100) / 100.0 - 0.5) * 4.0
    }

    // MARK: - Podium

    private var podiumView: some View {
        VStack(spacing: 0) {
            Text("Top Stories")
                .font(.roobert(36, weight: .semibold))
                .foregroundStyle(Color.ink)
                .tracking(-1.5)
                .padding(.top, 64)
                .padding(.bottom, 8)
            Text("Ranked by stars received")
                .font(.roobert(14))
                .foregroundStyle(Color.warmSilver)
                .padding(.bottom, 32)

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(Array(podiumStories.prefix(podiumRevealed).reversed().enumerated()), id: \.element.story.id) { idx, result in
                        let place = podiumStories.count - podiumRevealed + 1 + idx
                        podiumCard(result: result, place: place)
                            .transition(.asymmetric(
                                insertion: .scale(scale: 0.8, anchor: .top).combined(with: .opacity),
                                removal: .opacity
                            ))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }

            if podiumRevealed == podiumStories.count {
                Button("Done") { onDone() }
                    .buttonStyle(PlayfulPillButtonStyle(background: .matcha300, foreground: .matcha800))
                    .padding(.horizontal, 28)
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private func podiumCard(result: StoryResult, place: Int) -> some View {
        let medals: [Color] = [.pomegranate400, .warmSilver, .lemon500]
        let medalColor = place <= 3 ? medals[place - 1] : .oatLight
        let placeLabel = place == 1 ? "1st" : place == 2 ? "2nd" : "3rd"

        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(placeLabel)
                    .font(.roobert(13, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(medalColor))
                Spacer()
                HStack(spacing: 3) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.lemon500)
                    Text("\(result.totalStars)")
                        .font(.roobert(14, weight: .semibold))
                        .foregroundStyle(Color.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Text(result.story.story)
                .font(.roobert(15))
                .foregroundStyle(Color.white)
                .lineSpacing(3)
                .padding(.horizontal, 16)
                .padding(.bottom, 10)

            Text("by \(result.story.playerName)")
                .font(.roobert(12, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.55))
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
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
                    .foregroundStyle(Color.white)
            }
        )
        .rotationEffect(.degrees(cardRotation(for: result.story.playerName)))
    }

    // MARK: - Sequence

    private func startCountdown() {
        var n = 5
        func tick() {
            guard n > 0 else {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                    step = .pretenderReveal
                    featuredStory = mostVotedPretender?.story
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { showPretenderVerdict() }
                return
            }
            withAnimation { step = .countdown(n) }
            n -= 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { tick() }
        }
        tick()
    }

    private func showPretenderVerdict() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
            step = .pretenderVerdict
            verdictVisible = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { startAIReveal() }
    }

    private func startAIReveal() {
        verdictVisible = false
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
            step = .aiReveal
            featuredStory = mostVotedAI?.story
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { showAIVerdict() }
    }

    private func showAIVerdict() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
            step = .aiVerdict
            verdictVisible = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) { startPodium() }
    }

    private func startPodium() {
        let podium = Array(humanResults.prefix(3).reversed())
        verdictVisible = false
        withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
            step = .podium
            podiumStories = podium
        }
        revealPodiumEntry(index: 0, stories: podium)
    }

    private func revealPodiumEntry(index: Int, stories: [StoryResult]) {
        guard index < stories.count else { return }
        let delay: Double = index == stories.count - 1 ? 1.8 : 1.2
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                podiumRevealed = index + 1
            }
            revealPodiumEntry(index: index + 1, stories: stories)
        }
    }
}

#Preview {
    ResultsView(manager: MultipeerManager(), onDone: {})
}
