defmodule GameSiteWeb.Live.GuessingLive.Question do
  use GameSiteWeb, :live_view
  alias GameSiteWeb.WagerFunctions, as: Helper

  def get_new_answer() do
    new_answer()
  end

  def handle_answer(params, socket) do
    event_info = set_event_info(socket.assigns, params)

    {flash_type, flash_msg, score, attempt, answer, wager} =
      cond do
        event_info.correct ->
          highest_score = Helper.highest_score(event_info)
          {:info, "Correct!", highest_score, 1, get_new_answer(), event_info.wager}

        event_info.attempt < 5 ->
          {:error, "Incorrect.", socket.assigns.score, event_info.attempt + 1,
           socket.assigns.answer, event_info.wager}

        event_info.attempt >= 5 and event_info.current_score <= 0 ->
          {:error, "Out of Points, resetting.", 10, 1, new_answer(), 1}

        event_info.attempt >= 5 ->
          {:error, "Out of Guesses.", event_info.current_score, 1, new_answer(),
           min(event_info.wager, event_info.current_score)}
      end

    socket =
      socket
      |> clear_flash()
      |> assign(score: score, attempt: attempt, answer: answer, wager: wager)
      |> assign(form: to_form(%{}))
      |> put_flash(flash_type, flash_msg)

    {:noreply, socket}
  end

  defp new_answer(), do: Integer.to_string(Enum.random(1..10))

  defp set_event_info(assigns, %{"wager" => wager, "guess" => guess}) do
    parsed_wager = Helper.add_subtract_wager(wager, guess, assigns.answer)

    %{
      current_score: assigns.score + parsed_wager,
      highest_score: assigns.highest_score,
      wager: String.to_integer(wager),
      attempt: assigns.attempt,
      correct: assigns.answer == guess
    }
  end
end
