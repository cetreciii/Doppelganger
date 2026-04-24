# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

Doppelgänger is a local multiplayer iOS game where one human secretly impersonates an AI. Players write short stories using 3 random words; one human (the Pretender) tries to write like the AI. Others vote on which story is the AI's and which is the Pretender's.

- Swift / SwiftUI, iOS target
- Multipeer Connectivity for local network play (no internet required)
- Apple Foundation Models (`FoundationModels` framework) for word generation and AI story writing
- Minimum: 2 humans + 1 AI = 3 total players

## Build & Run

Open `Doppelgänger.xcodeproj` in Xcode and run on a device or simulator. There is no separate build script — use Xcode's standard build system (⌘B to build, ⌘R to run).

Foundation Models requires iOS 26+ / macOS 26+. Word generation falls back to a hardcoded pool if the model is unavailable.

## Architecture

**`ContentView.swift`** — Root. Owns `MultipeerManager` as `@StateObject` and drives navigation via an `AppScreen` enum (`home → createLobby / joinLobby → game`). Transition to `.game` is triggered by observing `manager.gameStarted`.

**`MultipeerManager.swift`** — Single `ObservableObject` managing all Multipeer Connectivity state. Hosts advertise; joiners browse. Messages are sent as JSON-encoded `LobbyMessage` enum cases (settings updates, player list, game start, words). The host's `MCPeerID.displayName` is used as the lobby name. Player names are set by the user on the home screen and assigned to `myPeerID` before entering the lobby.

**`GameView.swift`** — Writing phase UI. The host calls `generateAndBroadcastWords()` using `LanguageModelSession` then broadcasts words to all peers. All devices show a countdown timer, the 3 word cards, and a story `TextEditor`. Votes / revelation phases are not yet implemented.

**`DesignSystem.swift`** — All shared colors, typography, and button styles. Always use these tokens rather than raw hex values or system fonts.

**View files**: `HomeView.swift`, `CreateLobbyView.swift`, `JoinLobbyView.swift` handle lobby setup.

## Design System

The design is intentionally non-standard — no nav bars, tab bars, or system lists. Key rules from `DESIGN.md`:

- **Backgrounds**: Warm Cream `#faf9f7` (light) / Ube 900 `#32037d` (dark) — never cool gray
- **Cards**: white (light) / Ube 800 `#43089f` (dark), corner radius 20–24px for cards, 40px for sections
- **Borders**: Oat Border `#dad4c8` (light) / Dark Border `#aabbda` (dark); mix solid and dashed
- **Shadows**: Hard offset `x: -5, y: 5` or `x: -7, y: 7` with `radius: 0` — not soft blur shadows. In dark mode use `.ubeDeep` as shadow color instead of black.
- **Typography**: Always use `Font.roobert(_:weight:)` from `DesignSystem.swift`. Three weights only: `.semibold` (headings), `.medium` (UI), `.regular` (body).
- **Swatch palette**: Lemon, Slushie, Matcha, Ube, Pomegranate — used for card backgrounds and accents. All defined as `Color` extensions in `DesignSystem.swift`.
- **Animations**: Spring-based (`response: 0.2, dampingFraction: 0.55`), never linear fades for interactive elements.

When building new views, follow the pattern in `GameView.swift`: derive `isLight`, `bgColor`, `textColor`, `cardBg`, `secondaryText`, `borderColor` from `colorScheme` at the top of the view.
