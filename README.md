# GameSite

A multi-game web platform built with **Elixir**, **Phoenix**, and **LiveView**. Features real-time multiplayer games, persistent daily challenges, and a puzzle game with multiple board configurations — all running on a single LiveView-driven frontend with no client-side JS frameworks.

Live: [game.adamsites.com](https://game.adamsites.com)

---

## Architecture

The core design principle is a clean separation between **domain logic** and **LiveView rendering**:

- Game logic lives in pure Elixir modules — fully testable without a web layer
- LiveViews handle only user events and state diffing
- Multiplayer state is managed by a single GenServer per room, broadcast to connected clients via PubSub
- Shared scoring context and reusable UI components are used across all games

The test suite covers ~450 tests across game logic, contexts, LiveView integration, and UI components.

---

## Games

### Multiplayer

#### Multiplayer Poker
Real-time Texas Hold'em backed by a GenServer and Phoenix PubSub.

- Authenticated users create a named room, which appears in a shared lobby
- Other logged-in players can browse the lobby and join any open room
- A single GenServer holds the full game state for each room — dealing, betting rounds, hand evaluation, and player turns
- PubSub broadcasts state changes to all connected players in real time, keeping every client in sync without polling

#### Daily Wordle
A shared daily word challenge with per-user persistence.

- One word is generated per day and shared across all players
- Each user's guesses, attempt count, and completion status are stored in PostgreSQL
- Returning users resume exactly where they left off — the board is repopulated from their saved state
- A personal archive lets users review all their past Wordle results

---

### Single Player

#### Poker
Full single-player poker with hand evaluation and scoring logic implemented from scratch in Elixir.

#### Wordle
Classic word-guessing game with letter state tracking and keyboard feedback.

#### Pento
A puzzle game where players place pentomino pieces (5-unit shapes) onto a board. Multiple board sizes and piece sets are available, each with a different configuration. A dedicated picker route lets users choose which board to play.

#### Guessing Game
Number guessing game with attempt tracking and high-score persistence.

#### Rock Paper Scissors
Classic game with result tracking.

#### Math Game
Arithmetic challenge game with scoring and high-score tracking.

---

## Tech Stack

| Layer             | Technology                 |
| ----------------- | -------------------------- |
| Language          | Elixir                     |
| Web Framework     | Phoenix                    |
| Real-time UI      | Phoenix LiveView           |
| Multiplayer State | GenServer + Phoenix PubSub |
| Database ORM      | Ecto                       |
| Database          | PostgreSQL                 |
| Styling           | Tailwind CSS               |
| Testing           | ExUnit (~450 tests)        |
| Deployment        | Fly.io + Docker            |

---

## Project Structure

```
lib/
  game_site/
    accounts/           # User auth and session management
    scores/             # Shared scoring logic across games
    multi_poker/        # Multiplayer poker — GenServer, PubSub, hand logic
    multi_wordle/       # Daily Wordle — word generation, user progress, archive
    poker/              # Single-player poker domain logic
    wordle/             # Single-player Wordle logic
    guessing/           # Guessing game logic
    pento/              # Pentomino puzzle — board configs, piece placement
    math/               # Math game logic
    rock_paper_scissors/# RPS logic

  game_site_web/
    live/               # LiveView pages (one per game)
    components/         # Shared UI components reused across games

test/
  game_site/            # Domain logic and context tests
  game_site_web/        # LiveView and component tests
```

---

## Getting Started

### Prerequisites

- Elixir
- Erlang/OTP
- PostgreSQL
- Node.js

### Setup

```bash
mix setup
```

### Run the server

```bash
mix phx.server
# or inside IEx:
iex -S mix phx.server
```

Visit: [http://localhost:4000](http://localhost:4000)

---

## Running Tests

```bash
mix test
```

The suite includes tests for game logic, Ecto contexts, LiveView integration, and UI components.

---

## Learn More

- [Phoenix Framework](https://www.phoenixframework.org/)
- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view)
- [Elixir Forum](https://elixirforum.com)
- [My technical blog](https://blog.adamsites.com)
