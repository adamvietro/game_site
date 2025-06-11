defmodule GameSiteWeb.PokerForm do
  import Ecto.Changeset

  @fields %{
    cards: {:array, :any},
    hand: {:array, :any},
    score: :integer,
    wager: :integer,
    bet: :integer,
    highest_score: :integer,
    form: :map,
    state: :string
  }
  @default_values %{
    score: 100,
    highest_score: 0,
    wager: 10,
    form: %{},
    hand: [],
    state: :reset,
    cards: [],
    bet: 0
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
    |> validate_wager_less_than_or_equal_to_score()
    |> validate_inclusion(:state, ["initial", "dealt", "final", "reset"])
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

  defp validate_wager_less_than_or_equal_to_score(changeset) do
    score = get_field(changeset, :score)
    wager = get_field(changeset, :wager)

    if is_number(score) and is_number(wager) and wager > score do
      add_error(changeset, :wager, "must be less than or equal to your score")
    else
      changeset
    end
  end
end
