# Doppelgänger — Game Rules & Design Reference

## Concept

Doppelgänger is a local multiplayer iOS game where human players compete alongside an AI (Apple Foundation Model). One human secretly plays as a Pretender, trying to pass as the AI. The rest must unmask both.

---

## Players & Roles

**Lobby structure:** N humans join. The AI is automatically added as the (N+1)th player. Minimum: 2 humans (3 total). The total player count is always N + 1.

Roles are assigned randomly at the start of each game and are shown **only** to the assigned player — never broadcast to the group.

| Role | Count | Assigned to |
|---|---|---|
| Normal Player | N - 1 | Humans |
| Pretender | 1 | Human |
| AI | 1 | Apple Foundation Model |

### Role objectives

- **Normal Player:** Identify which story was written by the AI and which was written by the Pretender.
- **Pretender:** Write a story convincing enough that every player votes you as the AI.
- **AI:** Write a story based on the three words (no explicit objective — it is the target).

---

## Winning Conditions

- **Normal players win** when they correctly identify both the AI's story and the Pretender's story.
- **Pretender wins** when every player votes their story as the AI's story (full deception achieved).

---

## Game Flow

### 1. Main Menu
Entry point of the app.

### 2. Lobby
- Players join via **Multipeer Connectivity** (local network, no internet required).
- When the host starts the game, the AI is automatically added as the final participant.

### 3. Role Assignment
- Each player is privately shown their role on their own device.
- No role information is shared between devices.

### 4. Writing Phase
- **Apple Foundation Model** generates **3 random words**, shown simultaneously to all players.
- Each player has **60 seconds** to write a short story incorporating the three words.
- A text edit card is displayed on screen during this phase.

### 5. Voting Phase
- All stories are presented in a **swipeable card carousel** (cards, swipe left/right) — for reading and sparking out-loud discussion between players.
- Once they've read the stories, each player casts exactly **2 votes**:
  - 1 vote for which story they believe was written by the **AI**
  - 1 vote for which story they believe was written by the **Pretender**
  - (both votes must point to different stories)
- The carousel is a reading tool; the real discussion happens verbally between players.
- Players have **2 minutes** to vote.
- Voting ends early if all players have submitted their votes.

### 6. Revelation
- Results are revealed once the timer expires or all votes are in.
- Winner is determined based on the winning conditions above.

---

## Open Questions (to be resolved before implementation)

1. ~~**Voting logic:**~~ **Resolved.** Each player casts 2 fixed votes: one for the AI story, one for the Pretender story. The carousel is a reading/discussion tool; voting is a separate, constrained action.
2. ~~**Minimum players:**~~ **Resolved.** Minimum 2 humans (3 total with AI). Maximum is unconstrained for now.
3. ~~**Visual design:**~~ **Resolved.** Playful, casual, colorful — a deliberate break from Apple HIG. The app should feel handmade and joyful, like something people play after work when chilling. No standard iOS chrome (no nav bars, tab bars, or system lists). Everything custom. Two themes: light mode on Warm Cream (`#faf9f7`), dark mode on Ube 900 (`#32037d`). The swatch palette works across both.
