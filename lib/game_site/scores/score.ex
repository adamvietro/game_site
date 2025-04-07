defmodule GameSite.Scores.Score do
  use Ecto.Schema
  import Ecto.Changeset

  schema "scores" do
    field :score, :integer
    belongs_to :game, GameSite.Games.Game
    belongs_to :user, GameSite.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(score, attrs) do
    score
    |> cast(attrs, [:score, :user_id, :game_id])
    |> validate_required([:score, :user_id, :game_id])
    |> foreign_key_constraint(:game_id)
    |> foreign_key_constraint(:user_id)
  end
end
