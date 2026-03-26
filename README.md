# 🎮 GameSite

GameSite is a collection of interactive browser-based games built with Elixir, Phoenix, and LiveView.
It focuses on real-time gameplay, state management, and clean functional design.

--------------------------------------------------

🚀 Features

- Real-time gameplay powered by Phoenix LiveView
- Multiple games with shared scoring concepts:
  - Math Game
  - Guessing Game
  - Rock Paper Scissors
  - Poker
  - Pento (puzzle game)
  - Wordle-style game
- Score tracking and high score support
- User authentication
- Component-driven UI using function and live components

--------------------------------------------------

🛠️ Getting Started

Prerequisites

- Elixir (1.14+ recommended)
- Erlang/OTP
- Node.js (if assets are used)

Setup

mix setup

Run the server

mix phx.server

Or inside IEx:

iex -S mix phx.server

Then visit:

http://localhost:4000

--------------------------------------------------

🧱 Project Structure

lib/
  game_site/
    accounts/        # authentication + users
    scores/          # scoring logic
  game_site_web/
    live/            # LiveView modules for each game
    components/      # reusable UI components

test/
  game_site_web/
    live/            # LiveView + component tests

--------------------------------------------------

🧪 Testing

Run all tests:

mix test

The project includes:

- Unit tests for game logic modules
- Component tests using render_component/2
- LiveView event tests

--------------------------------------------------

🎯 Design Goals

- Keep game logic pure and testable
- Separate UI from domain logic
- Use LiveView for stateful, interactive experiences
- Build reusable components across games

--------------------------------------------------

<!-- 📌 TODO / Notes

Core Improvements
- Better score display with dropdown UI
- Create a struct per game:
  - Math
  - Guessing
  - Rock Paper Scissors
- Separate contexts:
  - Guessing
  - Math

Scoring
- Add scores to sidebar for each game
- Make scores work for Pento
- Add highest score tracking

Gameplay Features
- Wordle:
  - Add keyboard input support
  - Daily Wordle mode

- Poker:
  - Show result of poker hand
  - Add multiplayer support

Testing
- Add more robust test coverage -->

--------------------------------------------------

