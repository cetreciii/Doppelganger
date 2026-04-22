import SwiftUI
import MultipeerConnectivity

struct CreateLobbyView: View {
    @ObservedObject var manager: MultipeerManager
    let onBack: () -> Void

    @State private var settings = GameSettings()

    @Environment(\.colorScheme) private var colorScheme
    private var isLight: Bool { colorScheme == .light }
    private var bgColor: Color { isLight ? .canvas : .ube900 }
    private var textColor: Color { isLight ? .ink : .white }
    private var cardBg: Color { isLight ? .white : .ube800 }
    private var borderColor: Color { isLight ? .oatBorder : .darkBorder }
    private var secondaryText: Color { isLight ? .warmSilver : .ube300 }
    private var rowDivider: Color { isLight ? .oatLight : Color(hex: "3a1480") }

    var canStart: Bool { manager.connectedPeers.count >= 1 }

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 24)
                    .padding(.top, 60)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        settingsCard
                        playersCard
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 28)
                    .padding(.bottom, 120)
                }
            }

            VStack {
                Spacer()
                startButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 52)
            }
        }
        .onAppear {
            manager.startHosting()
        }
        .onChange(of: settings) { _, newValue in
            manager.updateSettings(newValue)
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Back")
                        .font(.roobert(15, weight: .medium))
                }
                .foregroundStyle(secondaryText)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("Your lobby")
                    .font(.roobert(13, weight: .semibold))
                    .foregroundStyle(secondaryText)
                    .tracking(0.6)
                    .textCase(.uppercase)
                Text(manager.myPeerID.displayName)
                    .font(.roobert(13, weight: .medium))
                    .foregroundStyle(textColor)
            }
        }
    }

    // MARK: - Settings Card

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Game settings")
                .font(.roobert(13, weight: .semibold))
                .tracking(0.6)
                .textCase(.uppercase)
                .foregroundStyle(secondaryText)
                .padding(.bottom, 14)

            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(cardBg)
                    .shadow(color: .black.opacity(0.22), radius: 10, x: -4, y: 4)

                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [14, 5]))
                    .foregroundStyle(borderColor)

                VStack(spacing: 0) {
                    stepperRow(
                        label: "AIs in the game",
                        value: $settings.numberOfAI,
                        range: 1...3
                    )
                    divider
                    stepperRow(
                        label: "Pretenders",
                        value: $settings.numberOfPretenders,
                        range: 1...3
                    )
                    divider
                    timePickerRow(
                        label: "Writing time",
                        options: [60, 90, 120],
                        labels: ["1 min", "90 sec", "2 min"],
                        value: $settings.writingTime
                    )
                    divider
                    timePickerRow(
                        label: "Voting time",
                        options: [60, 120, 180],
                        labels: ["1 min", "2 min", "3 min"],
                        value: $settings.votingTime
                    )
                }
                .padding(20)
            }
        }
    }

    // MARK: - Players Card

    private var playersCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Players in lobby")
                    .font(.roobert(13, weight: .semibold))
                    .tracking(0.6)
                    .textCase(.uppercase)
                    .foregroundStyle(secondaryText)
                Spacer()
                Text("\(manager.allPlayerNames.count)")
                    .font(.roobert(13, weight: .semibold))
                    .foregroundStyle(secondaryText)
            }
            .padding(.bottom, 14)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(cardBg)
                    .shadow(color: .black.opacity(0.22), radius: 10, x: -4, y: 4)

                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [14, 5]))
                    .foregroundStyle(borderColor)

                Group {
                    if manager.allPlayerNames.isEmpty {
                        waitingIndicator
                            .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .topLeading)))
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(manager.allPlayerNames, id: \.self) { name in
                                playerChip(name, isYou: name == manager.myPeerID.displayName)
                                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .topLeading)))
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: manager.allPlayerNames)
                .padding(20)
            }
        }
    }

    private var waitingIndicator: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(secondaryText)
            Text("Waiting for players to join…")
                .font(.roobert(15))
                .foregroundStyle(secondaryText)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Start Button

    private var startButton: some View {
        Button {
            manager.startGame()
        } label: {
            Text(canStart ? "Start game" : "Waiting for players…")
                .font(.roobert(22, weight: .regular))
        }
        .buttonStyle(PlayfulPillButtonStyle(
            background: canStart ? .matcha300 : (isLight ? .oatLight : Color(hex: "3a1480")),
            foreground: canStart ? .matcha800 : secondaryText,
            shadowOffset: canStart ? 7 : 0
        ))
        .disabled(!canStart)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: canStart)
    }

    // MARK: - Row Helpers

    private var divider: some View {
        Rectangle()
            .fill(rowDivider)
            .frame(height: 1)
            .padding(.vertical, 16)
    }

    private func stepperRow(label: String, value: Binding<Int>, range: ClosedRange<Int>) -> some View {
        HStack {
            Text(label)
                .font(.roobert(16, weight: .medium))
                .foregroundStyle(textColor)
            Spacer()
            HStack(spacing: 2) {
                stepperButton(symbol: "minus") {
                    if value.wrappedValue > range.lowerBound { value.wrappedValue -= 1 }
                }
                Text("\(value.wrappedValue)")
                    .font(.roobert(18, weight: .semibold))
                    .foregroundStyle(textColor)
                    .frame(width: 32, alignment: .center)
                stepperButton(symbol: "plus") {
                    if value.wrappedValue < range.upperBound { value.wrappedValue += 1 }
                }
            }
        }
    }

    private func stepperButton(symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(textColor)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isLight ? Color.oatLight : Color(hex: "32037d"))
                )
        }
    }

    private func timePickerRow(label: String, options: [Int], labels: [String], value: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(label)
                .font(.roobert(16, weight: .medium))
                .foregroundStyle(textColor)
            HStack(spacing: 8) {
                ForEach(Array(zip(options, labels)), id: \.0) { option, optLabel in
                    Button {
                        value.wrappedValue = option
                    } label: {
                        Text(optLabel)
                            .font(.roobert(13, weight: value.wrappedValue == option ? .semibold : .regular))
                            .foregroundStyle(value.wrappedValue == option ? (isLight ? .white : .ink) : secondaryText)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().fill(value.wrappedValue == option ? (isLight ? Color.ube800 : .white) : (isLight ? Color.oatLight : Color(hex: "32037d")))
                            )
                    }
                }
                Spacer()
            }
        }
    }

    private func playerChip(_ name: String, isYou: Bool) -> some View {
        HStack(spacing: 5) {
            if isYou {
                Circle()
                    .fill(Color.lemon500)
                    .frame(width: 6, height: 6)
            }
            Text(isYou ? "\(name) (you)" : name)
                .font(.roobert(13, weight: isYou ? .semibold : .regular))
                .foregroundStyle(isYou ? textColor : secondaryText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            Capsule()
                .fill(isYou ? (isLight ? Color.lemon400.opacity(0.3) : Color.lemon500.opacity(0.2)) : (isLight ? Color.oatLight : Color(hex: "3a1480")))
        )
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        let height = rows.map { $0.map { $0.height }.max() ?? 0 }.reduce(0) { $0 + $1 } + CGFloat(max(0, rows.count - 1)) * spacing
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            let rowHeight = row.map { $0.height }.max() ?? 0
            var x = bounds.minX
            for item in row {
                item.view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(item.size))
                x += item.width + spacing
            }
            y += rowHeight + spacing
        }
    }

    private struct ItemLayout {
        let view: LayoutSubview
        let size: CGSize
        var width: CGFloat { size.width }
        var height: CGFloat { size.height }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[ItemLayout]] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[ItemLayout]] = [[]]
        var rowWidth: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, !rows[rows.count - 1].isEmpty {
                rows.append([])
                rowWidth = 0
            }
            rows[rows.count - 1].append(ItemLayout(view: view, size: size))
            rowWidth += size.width + spacing
        }
        return rows
    }
}

#Preview("Light") {
    CreateLobbyView(manager: MultipeerManager(), onBack: {})
}
#Preview("Dark") {
    CreateLobbyView(manager: MultipeerManager(), onBack: {})
        .preferredColorScheme(.dark)
}
