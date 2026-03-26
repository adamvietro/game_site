defmodule GameSiteWeb.Live.GuessingLive.Question do
  use GameSiteWeb, :live_view
  alias GameSiteWeb.WagerFunctions, as: Helper

  def get_new_answer() do
    new_answer()
  end

  defp new_answer(), do: Integer.to_string(Enum.random(1..10))

  def set_event_info(assigns, %{"wager" => wager, "guess" => guess}) do
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
