defmodule GameSiteWeb.Live.RockPaperScissorsLive.GameLogic do
  use GameSiteWeb, :live_view

  defstruct [:player, :computer, :current_score, :wager, :highest_score, :form, :score, :outcome]

  def set_computer_choice() do
    computer_choice()
  end

  def set_game_board_info(socket, params) do
    game_board_info(socket, params)
  end

  defp event_info(socket, %{"wager" => wager, "player_choice" => player}) do
    parsed_wager = parsed_wager(wager, player, socket.assigns.computer)

    %{
      player: player,
      computer: socket.assigns.computer,
      current_score: socket.assigns.score + parsed_wager,
      score: socket.assigns.score,
      wager: if(wager == "", do: 1, else: String.to_integer(wager)),
      highest_score: max(socket.assigns.score + parsed_wager, socket.assigns.highest_score),
      form: to_form(%{wager: wager})
    }
  end

  defp computer_choice() do
    Enum.random(["rock", "paper", "scissor"])
  end

  defp player_beats_computer?(player, computer),
    do: {player, computer} in [{"rock", "scissor"}, {"scissor", "paper"}, {"paper", "rock"}]

  defp parsed_wager("", player, computer) do
    if player_beats_computer?(player, computer), do: 1, else: -1
  end

  defp parsed_wager(wager, player, computer) do
    if player_beats_computer?(player, computer),
      do: String.to_integer(wager),
      else: -1 * String.to_integer(wager)
  end

  defp game_board_info(socket, params) do
    event_info =
      event_info(socket, params)

    cond do
      event_info.current_score <= 0 ->
        socket =
          socket
          |> put_flash(:error, "Score at 0, resetting.")
          |> assign(computer: computer_choice())
          |> assign(score: 10)
          |> assign(wager: 1)
          |> assign(form: to_form(%{"wager" => 1}))
          |> assign(outcome: "")

        {:noreply, socket}

      event_info.computer == event_info.player ->
        socket =
          socket
          |> assign(computer: computer_choice())
          |> assign(wager: event_info.wager)
          |> assign(form: to_form(%{"wager" => event_info.wager}))
          |> assign(outcome: "You Tie!")

        {:noreply, socket}

      player_beats_computer?(event_info.player, event_info.computer) ->
        socket =
          socket
          |> assign(computer: computer_choice())
          |> assign(score: event_info.current_score)
          |> assign(wager: event_info.wager)
          |> assign(highest_score: max(event_info.current_score, event_info.highest_score))
          |> assign(form: to_form(%{"wager" => event_info.wager}))
          |> assign(outcome: "You Win!")

        {:noreply, socket}

      true ->
        socket =
          socket
          |> assign(computer: computer_choice())
          |> assign(wager: min(event_info.wager, event_info.current_score))
          |> assign(score: event_info.current_score)
          |> assign(form: to_form(%{"wager" => event_info.wager}))
          |> assign(outcome: "You Lose!")

        {:noreply, socket}
    end
  end

  defp outcome_multiplier(outcome) do
    case outcome do
      :win -> 1
      :lose -> -1
      :tie -> 0
    end
  end

  defp determine_round(%__MODULE__{} = game_state) do
    game_state
    |> determine_outcome()
    |> determine_score()
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
end
