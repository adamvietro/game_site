defmodule GameSiteWeb.PokerForm do
  import Ecto.Changeset

  @fields %{
    cards: {:array, :map},
    hand: {:array, :map},
    score: :integer,
    wager: :integer,
    highest_score: :integer,

  }
  @default_values %{
    # id: nil,
    # name: nil
  }
  def default_values(overrides \\ %{}) do
    Map.merge(@default_values, overrides)
  end

  def parse(params) do
    {@default_values, @fields}
    |> cast(params, Map.keys(@fields))
    |> validate_number(:score, greater_than_or_equal_to: 0)
    |> validate_number(:highest_score, greater_than_or_equal_to: 0)
    |> apply_action(:insert)
  end

  def change_values(values \\ @default_values) do
    {values, @fields}
    |> cast(%{}, Map.keys(@fields))
  end

  @spec contains_filter_values?(any()) :: boolean()
  def contains_filter_values?(opts) do
    @fields
    |> Map.keys()
    |> Enum.any?(fn key -> Map.get(opts, key) end)
  end
end
