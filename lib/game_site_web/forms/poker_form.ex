defmodule GameSiteWeb.PokerForm do
  import Ecto.Changeset

  @fields %{
    cards: {:array, :any},
    hand: {:array, :any},
    score: :integer,
    wager: :integer,
    highest_score: :integer,
    form: :map,
    final: :boolean

  }
  @default_values %{
    score: 100,
    highest_score: 0,
    wager: 10,
    form: %{},
    hand: [],
    final: false,
    cards: []
  }
  def default_values(overrides \\ %{}) do
    Map.merge(@default_values, overrides)
  end

  def parse(params) do
    {@default_values, @fields}
    |> cast(params, Map.keys(@fields))
    |> validate_number(:score, greater_than_or_equal_to: 0)
    |> validate_number(:highest_score, greater_than_or_equal_to: 0)
    |> validate_number(:wager, greater_than_or_equal_to: 0)
    |> apply_action(:insert)
  end

  def change_values(values \\ @default_values) do
    {values, @fields}
    |> cast(%{}, Map.keys(@fields))
  end

  def passed?(params) do
    case parse(params) do
      {:ok, valid} -> valid
      {:error, changeset} -> {:error, changeset}
    end
  end
end
