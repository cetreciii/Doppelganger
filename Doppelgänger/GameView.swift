import SwiftUI
import FoundationModels
internal import Combine

struct GameView: View {
    @ObservedObject var manager: MultipeerManager
    let onGameEnd: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }
    private var bgColor: Color { isLight ? .canvas : .ube900 }
    private var textColor: Color { isLight ? .ink : .white }
    private var cardBg: Color { isLight ? .white : .ube800 }
    private var secondaryText: Color { isLight ? .warmSilver : .ube300 }
    private var trackColor: Color { isLight ? .oatLight : Color(hex: "3a1480") }

    private var writingTime: Int { manager.settings.writingTime }

    @State private var timeRemaining: Int = 0
    @State private var storyText = ""
    @State private var words: [String] = []
    @State private var isLoadingWords = true
    @State private var showTimesUp = false
    @State private var gameEnded = false
    @FocusState private var storyFocused: Bool

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            gameEndedView.opacity(gameEnded ? 1 : 0)
            mainContent.opacity(gameEnded ? 0 : 1)
            timesUpOverlay.opacity(showTimesUp ? 1 : 0)
        }
        .onReceive(ticker) { _ in
            guard !showTimesUp, !gameEnded else { return }
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                storyFocused = false
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    showTimesUp = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation {
                        showTimesUp = false
                        gameEnded = true
                    }
                }
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
            if manager.isHost {
                await generateAndBroadcastWords()
            }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            timerRing
                .padding(.top, 64)

            Spacer().frame(height: 28)

            wordsSection
                .padding(.horizontal, 24)

            Spacer().frame(height: 20)

            storyCard
                .padding(.horizontal, 24)

            Spacer()
        }
    }

    // MARK: - Timer Ring

    private var timerRing: some View {
        ZStack {
            Circle()
                .stroke(trackColor, lineWidth: 6)
                .frame(width: 88, height: 88)

            Circle()
                .trim(from: 0, to: CGFloat(timeRemaining) / CGFloat(max(writingTime, 1)))
                .stroke(timerColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .frame(width: 88, height: 88)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: timeRemaining)

            Text("\(timeRemaining)")
                .font(.roobert(30, weight: .semibold))
                .foregroundStyle(textColor)
                .monospacedDigit()
                .contentTransition(.numericText(countsDown: true))
                .animation(.linear(duration: 0.3), value: timeRemaining)
        }
    }

    private var timerColor: Color {
        let fraction = Double(timeRemaining) / Double(max(writingTime, 1))
        if fraction > 0.5 { return .matcha300 }
        if fraction > 0.2 { return .lemon500 }
        return .pomegranate400
    }

    // MARK: - Words Section

    private let wordStyles: [(bg: Color, fg: Color, angle: Double)] = [
        (.lemon500,   .ink,      -2.5),
        (.slushie500, .ink,       1.5),
        (.matcha300,  .matcha800, -1.0),
    ]

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
                    ForEach(0..<3, id: \.self) { i in
                        skeletonCard(angle: wordStyles[i].angle)
                    }
                } else {
                    ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                        wordCard(word, style: wordStyles[index % wordStyles.count])
                    }
                }
            }
        }
    }

    private func wordCard(_ word: String, style: (bg: Color, fg: Color, angle: Double)) -> some View {
        let shadowColor: Color = isLight ? .black : .ubeDeep
        return Text(word)
            .font(.roobert(30, weight: .semibold))
            .tracking(-0.8)
            .foregroundStyle(style.fg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(style.bg)
                    .shadow(color: shadowColor, radius: 0, x: -5, y: 5)
            )
            .rotationEffect(.degrees(style.angle))
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
                .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 2)

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
            timesUpCard
        }
    }

    private var timesUpCard: some View {
        let background = RoundedRectangle(cornerRadius: 28)
            .fill(cardBg)
            .shadow(color: .black.opacity(0.3), radius: 24, x: 0, y: 8)
        return VStack(spacing: 12) {
            Text("Time's up!")
                .font(.roobert(48, weight: .semibold))
                .foregroundStyle(textColor)
                .tracking(-2)
            Text("Pens down.")
                .font(.roobert(20))
                .foregroundStyle(secondaryText)
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 44)
        .background(background)
        .padding(.horizontal, 40)
    }

    // MARK: - Game Ended

    private var gameEndedView: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("Game ended")
                .font(.roobert(44, weight: .semibold))
                .foregroundStyle(textColor)
                .tracking(-1.8)
                .transition(.opacity)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Word Generation (host only)

    private func generateAndBroadcastWords() async {
        let generated: [String]

        if #available(iOS 26.0, macOS 26.0, *), SystemLanguageModel.default.isAvailable {
            do {
                let session = LanguageModelSession()
                let response = try await session.respond(
                    to: "Give me exactly 3 unrelated, imaginative nouns for a creative writing prompt. Reply with only the 3 words separated by commas, lowercase, no punctuation, no explanation."
                )
                let raw = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
                let parsed = raw.split(separator: ",").map {
                    $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                }
                generated = parsed.count >= 3 ? Array(parsed.prefix(3)) : fallbackWords()
            } catch {
                generated = fallbackWords()
            }
        } else {
            generated = fallbackWords()
        }

        manager.broadcastWords(generated)
        words = generated
        isLoadingWords = false
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
}

#Preview("Light") {
    GameView(manager: MultipeerManager(), onGameEnd: {})
}
#Preview("Dark") {
    GameView(manager: MultipeerManager(), onGameEnd: {})
        .preferredColorScheme(.dark)
}
