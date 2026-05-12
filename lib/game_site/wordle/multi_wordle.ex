defmodule GameSite.Wordle.MultiWordle do
  use Ecto.Schema
  import Ecto.Changeset

  schema "multi_wordles" do
    field :date, :date
    field :word, :string

    has_many :user_wordles, GameSite.Wordle.UserWordle

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(multi_wordle, attrs) do
    multi_wordle
    |> cast(attrs, [:word, :date])
    |> validate_required([:word, :date])
  end
end
