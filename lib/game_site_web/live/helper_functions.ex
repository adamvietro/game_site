defmodule GameSiteWeb.HelperFunctions do
  @moduledoc """
    These are a set of helper functions for the entire site that will be used for more than
    one set of games.
  """

  def highest_score(event_info), do: max(event_info.current_score, event_info.highest_score)

  def parse_wager(nil), do: 1
  def parse_wager(""), do: 1

  def parse_wager(wager) do
    case Integer.parse(wager) do
      {int, _} -> int
      :error -> 1
    end
  end

  def add_subtract_wager(wager, guess, answer) do
    if guess == answer do
      wager
    else
      wager * -1
    end
  end
end
