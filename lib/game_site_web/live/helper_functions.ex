defmodule GameSiteWeb.HelperFunctions do
  @moduledoc """
    These are a set of helper functions for the entire site that will be used for more than
    one set of games.
  """

  def highest_score(event_info), do: max(event_info.current_score, event_info.highest_score)

  # def parse_wager(nil), do: 1
  # def parse_wager(""), do: 1

  # def parse_wager(wager) do
  #   case Integer.parse(wager) do
  #     {int, _} -> int
  #     :error -> 1
  #   end
  # end

  def add_subtract_wager("", guess, answer) do
    # IO.inspect("Quote")
    if guess == to_string(answer) do
      1
    else
      -1
    end
  end

  def add_subtract_wager(wager, guess, answer) do
    # IO.inspect("normal")
    if guess == to_string(answer) do
      String.to_integer(wager)
    else
      String.to_integer(wager) * -1
    end
  end

  def correct?(guess, answer) do
    guess == to_string(answer)
  end

  def wager_parse(wager) do
    if wager == "", do: 1, else: String.to_integer(wager)
  end
end
