# GameSite

GameSite is a collection of interactive browser-based games built with **Elixir**, **Phoenix**, and **LiveView**.

The project focuses on real-time gameplay, clean state management, reusable components, and separating game logic from the UI.

---

## Features

- Real-time gameplay with Phoenix LiveView
- User accounts and authentication
- Score tracking and high scores
- Component-driven UI
- Single-player and multiplayer games
- Testable game logic separated from LiveView code

---

## Games

### Single-player games

- Math Game
- Guessing Game
- Rock Paper Scissors
- Poker
- Pento
- Wordle-style game

### Multiplayer games

- Multiplayer Poker
- Multiplayer Wordle

---

## Tech Stack

- Elixir
- Phoenix
- Phoenix LiveView
- Ecto
- PostgreSQL
- Tailwind CSS
- ExUnit

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
```

Or inside IEx:

```bash
iex -S mix phx.server
```

Then visit:

```text
http://localhost:4000
```

---

## Running Tests

```bash
mix test
```

The test suite includes:

* Game logic tests
* Context tests
* LiveView tests
* Component tests

---

## Project Structure

```text
lib/
  game_site/
    accounts/          # Users and authentication
    scores/            # Shared scoring logic
    multi_poker/       # Multiplayer poker domain logic
    multi_wordle/      # Multiplayer Wordle domain logic
    guessing/          # Guessing Game Logic
    pento/             # Pento Game Logic
    poker/             # Poker Game Logic
    math/              # Math Game Logic
    rock_paper_scissors# RPS Game Logic
    wordle             # Single Player Wordle Game Logic

  game_site_web/
    live/              # LiveView pages
    components/        # Shared UI components

test/
  game_site/
  game_site_web/
```

---

## Design Goals

* Keep domain logic pure and testable
* Keep LiveViews focused on rendering and user events
* Use GenServers for real-time multiplayer room state
* Reuse components across games
* Build features incrementally with tests

---

## Current Focus

- Refining multiplayer poker gameplay and edge cases
- Expanding multiplayer Wordle features and polish
- Improving UI consistency across games
- Continuing to improve test coverage
- Adding new gameplay systems and reusable components

---

## Learn More

* [Phoenix](https://www.phoenixframework.org/)
* [Phoenix Docs](https://hexdocs.pm/phoenix)
* [Phoenix Guides](https://hexdocs.pm/phoenix/overview.html)
* [Elixir Forum](https://elixirforum.com/c/phoenix-forum)
