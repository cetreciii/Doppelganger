import SwiftUI

struct RoleRevealView: View {
    @ObservedObject var manager: MultipeerManager
    let onContinue: () -> Void

    @State private var showSuspense = false
    @State private var showCard = false
    @State private var showSubtitle = false
    @State private var countdown = 4

    private let revealDelay: Double = 1.6
    private let autoAdvanceSeconds = 4

    var body: some View {
        ZStack {
            Color.ube800.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                suspenseLabel
                Spacer().frame(height: 32)
                roleCard
                Spacer().frame(height: 28)
                subtitleLabel
                Spacer()
                countdownBar
                    .padding(.bottom, 52)
            }
        }
        .onAppear {
            if manager.isHost {
                manager.broadcastRoles()
                manager.beginWordGeneration()
                startRevealSequence()
            }
        }
        .onChange(of: manager.myRoleAssigned) { _, assigned in
            if assigned && !manager.isHost {
                startRevealSequence()
            }
        }
    }

    // MARK: - Subviews

    private var suspenseLabel: some View {
        Text("Your role")
            .font(.roobert(13, weight: .semibold))
            .tracking(2.0)
            .textCase(.uppercase)
            .foregroundStyle(Color.ube300.opacity(showSuspense ? 1 : 0))
            .animation(.easeIn(duration: 0.5), value: showSuspense)
    }

    private var roleCard: some View {
        let isPretender = manager.myRole == .pretender
        let cardColor: Color = isPretender ? .pomegranate400 : .matcha300
        let label = isPretender ? "Pretender" : "Human"
        let tilt: Double = isPretender ? -3 : 2

        return VStack(spacing: 4) {
            Text(label)
                .font(.roobert(64, weight: .semibold))
                .tracking(-3)
                .foregroundStyle(Color.ink)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 36)
        .padding(.vertical, 48)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(cardColor)
                .shadow(color: .black, radius: 0, x: -7, y: 7)
        )
        .padding(.horizontal, 32)
        .rotationEffect(.degrees(showCard ? tilt : 0))
        .scaleEffect(showCard ? 1 : 0.6)
        .opacity(showCard ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showCard)
    }

    private var subtitleLabel: some View {
        let isPretender = manager.myRole == .pretender
        let text = isPretender
            ? "Write like an AI. Don't get caught."
            : "Spot the Pretender. Write like yourself."

        return Text(text)
            .font(.roobert(17, weight: .medium))
            .foregroundStyle(Color.white.opacity(0.7))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 48)
            .opacity(showSubtitle ? 1 : 0)
            .offset(y: showSubtitle ? 0 : 10)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showSubtitle)
    }

    private var countdownBar: some View {
        HStack(spacing: 6) {
            ForEach(0..<autoAdvanceSeconds, id: \.self) { i in
                RoundedRectangle(cornerRadius: 3)
                    .fill(i < (autoAdvanceSeconds - countdown)
                          ? Color.white.opacity(0.9)
                          : Color.white.opacity(0.2))
                    .frame(height: 4)
                    .animation(.linear(duration: 0.9), value: countdown)
            }
        }
        .frame(maxWidth: 120)
        .opacity(showSubtitle ? 1 : 0)
    }

    // MARK: - Logic

    private func startRevealSequence() {
        withAnimation { showSuspense = true }

        DispatchQueue.main.asyncAfter(deadline: .now() + revealDelay) {
            showCard = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + revealDelay + 0.4) {
            showSubtitle = true
            startCountdown()
        }
    }

    private func startCountdown() {
        var remaining = autoAdvanceSeconds
        countdown = remaining

        func tick() {
            guard remaining > 0 else {
                onContinue()
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                remaining -= 1
                countdown = remaining
                tick()
            }
        }
        tick()
    }
}

#Preview {
    RoleRevealView(manager: MultipeerManager(), onContinue: {})
}
