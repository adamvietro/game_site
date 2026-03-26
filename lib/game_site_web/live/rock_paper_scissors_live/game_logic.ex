defmodule GameSiteWeb.Live.RockPaperScissorsLive.GameLogic do
  use GameSiteWeb, :live_view

  defstruct player: nil,
            computer: nil,
            current_score: 0,
            wager: 1,
            highest_score: 0,
            form: %{"wager" => 1},
            score: 10,
            outcome: nil,
            message: "",
            flash_message: ""

  def set_computer_choice() do
    computer_choice()
  end

  def parse_wager(""), do: 1
  def parse_wager(nil), do: 1
  def parse_wager(wager), do: String.to_integer(wager)

  def determine_round(%__MODULE__{} = game_state) do
    game_state
    |> determine_outcome()
    |> determine_score()
    |> determine_highest_score()
    |> reset_game()
  end

  defp determine_outcome(%__MODULE__{player: player, computer: computer} = game_state) do
    outcome =
      cond do
        player == computer -> :tie
        player_beats_computer?(player, computer) -> :win
        true -> :lose
      end

    %__MODULE__{game_state | outcome: outcome}
  end

  defp determine_score(%__MODULE__{score: score, wager: wager, outcome: outcome} = game_state) do
    %__MODULE__{game_state | score: score + wager * outcome_multiplier(outcome)}
  end

  defp determine_highest_score(
         %__MODULE__{score: score, highest_score: highest_score} = game_state
       ) do
    %__MODULE__{game_state | highest_score: max(score, highest_score)}
  end

  defp reset_game(%__MODULE__{} = game_state) do
    computer = computer_choice()
    wager = determine_wager(game_state)

    case result(game_state) do
      :reset ->
        %__MODULE__{
          game_state
          | score: 10,
            outcome: nil,
            message: "",
            flash_message: "Score at 0, resetting.",
            computer: computer,
            wager: 1
        }

      :win ->
        %__MODULE__{
          game_state
          | outcome: nil,
            message: "You Win!!",
            computer: computer,
            wager: wager
        }

      :lose ->
        %__MODULE__{
          game_state
          | outcome: nil,
            message: "You Lose!!",
            computer: computer,
            wager: wager
        }

      :tie ->
        %__MODULE__{
          game_state
          | outcome: nil,
            message: "You Tie!!",
            computer: computer,
            wager: wager
        }
    end
  end

  defp computer_choice() do
    Enum.random(["rock", "paper", "scissor"])
  end

  defp player_beats_computer?(player, computer),
    do: {player, computer} in [{"rock", "scissor"}, {"scissor", "paper"}, {"paper", "rock"}]

  defp determine_wager(%__MODULE__{wager: wager, score: score}) do
    min(wager, score)
  end

  defp outcome_multiplier(outcome) do
    case outcome do
      :win -> 1
      :lose -> -1
      :tie -> 0
    end
  end

  defp result(%__MODULE__{outcome: outcome, score: score}) do
    cond do
      outcome == :lose and score <= 0 ->
        :reset

      outcome == :win ->
        :win

      outcome == :lose ->
        :lose

      outcome == :tie ->
        :tie
    end
  end
end
