defmodule GameSite.ScoresFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `GameSite.Scores` context.
  """

  @doc """
  Generate a score.
  """
  def score_fixture(attrs \\ %{}) do
    {:ok, score} =
      attrs
      |> Enum.into(%{
        score: 42
      })
      |> GameSite.Scores.create_score()

    score
  end
end
