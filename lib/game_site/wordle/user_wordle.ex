defmodule GameSite.Wordle.UserWordle do
  use Ecto.Schema
  import Ecto.Changeset

  schema "user_wordles" do
    field :status, :string
    field :entered_words, {:array, :string}
    field :attempts, :integer
    field :completed_at, :utc_datetime

    belongs_to :user, GameSite.Accounts.User
    belongs_to :multi_wordle, GameSite.Wordle.MultiWordle

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user_wordle, attrs) do
    user_wordle
    |> cast(attrs, [
      :entered_words,
      :attempts,
      :status,
      :completed_at,
      :user_id,
      :multi_wordle_id
    ])
    |> validate_required([
      :entered_words,
      :attempts,
      :status,
      :user_id,
      :multi_wordle_id
    ])
    |> assoc_constraint(:user)
    |> assoc_constraint(:multi_wordle)
  end
end
