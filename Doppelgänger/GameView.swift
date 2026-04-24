import SwiftUI
internal import Combine

struct GameView: View {
    @ObservedObject var manager: MultipeerManager
    let onGameEnd: () -> Void

    private var bgColor: Color { .canvas }
    private var textColor: Color { .ink }
    private var cardBg: Color { .white }
    private var secondaryText: Color { .warmSilver }
    private var trackColor: Color { .oatLight }
    private var borderColor: Color { .oatBorder }
    private var writingTime: Int { manager.settings.writingTime }

    @State private var timeRemaining: Int = 0
    @State private var storyText = ""
    @State private var words: [String] = []
    @State private var isLoadingWords = true
    @State private var showTimesUp = false
    @State private var showVoting = false
    @State private var showResults = false
    @FocusState private var storyFocused: Bool

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            if showResults {
                ResultsView(manager: manager, onDone: onGameEnd)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
            } else if showVoting {
                VotingView(manager: manager, onReveal: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { showResults = true }
                })
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
            } else {
                mainContent.opacity(showTimesUp ? 0.3 : 1)
                timesUpOverlay.opacity(showTimesUp ? 1 : 0)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showVoting)
        .onReceive(ticker) { _ in
            guard !showTimesUp, !showVoting else { return }
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                storyFocused = false
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { showTimesUp = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { enterVoting() }
            }
        }
        .onChange(of: manager.gameWords) { _, newWords in
            if !newWords.isEmpty && isLoadingWords {
                words = newWords
                isLoadingWords = false
            }
        }
        .task {
            timeRemaining = manager.settings.writingTime
            if manager.isHost { await manager.broadcastWords() }
        }
    }

    private func enterVoting() {
        manager.submitMyStory(storyText)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { showVoting = true }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            timerRing.padding(.top, 64)
            Spacer().frame(height: 28)
            wordsSection.padding(.horizontal, 24)
            Spacer().frame(height: 20)
            storyCard.padding(.horizontal, 24)
            Spacer()
        }
    }

    // MARK: - Timer Ring

    private var timerRing: some View {
        ZStack {
            Circle()
                .fill(cardBg)
                .frame(width: 112, height: 112)
                .shadow(color: .black.opacity(0.22), radius: 8, x: -3, y: 3)
            Circle()
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8, 5]))
                .foregroundStyle(borderColor)
                .frame(width: 112, height: 112)
            Circle()
                .stroke(trackColor, lineWidth: 5)
                .frame(width: 82, height: 82)
            Circle()
                .trim(from: 0, to: CGFloat(timeRemaining) / CGFloat(max(writingTime, 1)))
                .stroke(timerColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .frame(width: 82, height: 82)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: timeRemaining)
            VStack(spacing: 1) {
                Text("\(timeRemaining)")
                    .font(.roobert(30, weight: .semibold))
                    .foregroundStyle(textColor)
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.linear(duration: 0.3), value: timeRemaining)
                Text("sec")
                    .font(.roobert(11, weight: .medium))
                    .tracking(0.5)
                    .foregroundStyle(secondaryText)
            }
        }
    }

    private var timerColor: Color {
        let fraction = Double(timeRemaining) / Double(max(writingTime, 1))
        if fraction > 0.5 { return .matcha300 }
        if fraction > 0.2 { return .lemon500 }
        return .pomegranate400
    }

    // MARK: - Words Section

    private let wordStyles: [(bg: Color, fg: Color)] = [
        (.lemon500, .ink), (.slushie500, .ink), (.matcha300, .matcha800)
    ]
    @State private var wordAngles: [Double] = (0..<3).map { _ in Double.random(in: -3.5...3.5) }

    private var wordsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Your words")
                .font(.roobert(12, weight: .semibold))
                .tracking(1.0)
                .textCase(.uppercase)
                .foregroundStyle(secondaryText)
                .padding(.bottom, 14)
            VStack(spacing: 10) {
                if isLoadingWords {
                    ForEach(0..<3, id: \.self) { i in skeletonCard(angle: wordAngles[i]) }
                } else {
                    ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                        wordCard(word, style: wordStyles[index % wordStyles.count], angle: wordAngles[index % wordAngles.count])
                    }
                }
            }
        }
    }

    private func wordCard(_ word: String, style: (bg: Color, fg: Color), angle: Double) -> some View {
        Text(word)
            .font(.roobert(30, weight: .semibold))
            .tracking(-0.8)
            .foregroundStyle(style.fg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(style.bg)
                    .shadow(color: .black, radius: 0, x: -5, y: 5)
            )
            .rotationEffect(.degrees(angle))
    }

    private func skeletonCard(angle: Double) -> some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(trackColor)
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .rotationEffect(.degrees(angle))
            .opacity(0.5)
    }

    // MARK: - Story Card

    private var storyCard: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 20)
                .fill(cardBg)
                .shadow(color: .black.opacity(0.25), radius: 10, x: -4, y: 4)
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [14, 5]))
                .foregroundStyle(borderColor)
            if storyText.isEmpty {
                Text("Write your story here…")
                    .font(.roobert(17))
                    .foregroundStyle(secondaryText)
                    .padding(20)
                    .allowsHitTesting(false)
            }
            TextEditor(text: $storyText)
                .font(.roobert(17))
                .foregroundStyle(textColor)
                .scrollContentBackground(.hidden)
                .padding(14)
                .frame(minHeight: 200)
                .focused($storyFocused)
        }
    }

    // MARK: - Time's Up Overlay

    private var timesUpOverlay: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 8) {
                Text("Time's up!")
                    .font(.roobert(52, weight: .semibold))
                    .foregroundStyle(Color.ink)
                    .tracking(-2.5)
                Text("Pens down.")
                    .font(.roobert(20))
                    .foregroundStyle(Color.ink.opacity(0.55))
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 44)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.pomegranate400)
                    .shadow(color: .black, radius: 0, x: -7, y: 7)
            )
            .padding(.horizontal, 40)
            .rotationEffect(.degrees(-2.5))
        }
    }

}

#Preview {
    GameView(manager: MultipeerManager(), onGameEnd: {})
}
