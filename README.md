# Doppelgänger

A local multiplayer iOS game for friends. One of you is secretly pretending to be an AI — can the group figure out who?

## How it works

Players join a lobby over local network (Multipeer Connectivity). Each round, Apple's Foundation Model generates three random words and writes a short story. Every human does the same. One human — the Pretender — tries to write like an AI. The rest try to unmask them both.

## Roles

| Role | Assigned to | Objective |
|---|---|---|
| Normal Player | Most humans | Identify the AI's story and the Pretender's story |
| Pretender | One human | Convince everyone you are the AI |
| AI | Foundation Model | Write a story (it is the target) |

The number of players is always **N + 1** — N humans plus the AI, which joins automatically.

## Game flow

1. **Lobby** — players join via local network, minimum 2 humans
2. **Role assignment** — each player sees their role privately on their own device
3. **Writing phase** — 60 seconds to write a short story using the 3 random words
4. **Voting phase** — stories are shown in a swipeable card carousel; players discuss out loud, then each casts 2 votes: one for which story they think is the AI's, one for the Pretender's
5. **Revelation** — results are revealed and the winner is announced

## Winning conditions

- **Normal players win** — they correctly identify both the AI's story and the Pretender's story
- **Pretender wins** — every player votes their story as the AI's

## Design

Playful, casual, colorful — built to feel like a break from structure. Custom UI throughout, no standard iOS chrome. Light mode on warm cream, dark mode on deep purple.

## Tech

- Swift / SwiftUI
- Multipeer Connectivity (local network, no internet required)
- Apple Foundation Models
