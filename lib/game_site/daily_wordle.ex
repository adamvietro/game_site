defmodule GameSite.DailyWordle do
  @moduledoc """
  The Wordle context.
  """

  import Ecto.Query, warn: false
  alias GameSite.Repo

  alias GameSite.Wordle.MultiWordle
  alias GameSite.Wordle.UserWordle
  alias GameSite.Wordle.Words

  def get_multi_wordle!(id), do: Repo.get!(MultiWordle, id)

  def get_multi_wordle_by_date(date) do
    Repo.get_by(MultiWordle, date: date)
  end

  def get_today_wordle do
    get_multi_wordle_by_date(Date.utc_today())
  end

  def create_multi_wordle(attrs \\ %{}) do
    %MultiWordle{}
    |> MultiWordle.changeset(attrs)
    |> Repo.insert()
  end

  def update_multi_wordle(%MultiWordle{} = multi_wordle, attrs) do
    multi_wordle
    |> MultiWordle.changeset(attrs)
    |> Repo.update()
  end

  def get_user_wordle(user_id, multi_wordle_id) do
    Repo.get_by(UserWordle,
      user_id: user_id,
      multi_wordle_id: multi_wordle_id
    )
  end

  def get_user_wordle!(id), do: Repo.get!(UserWordle, id)

  def create_user_wordle(attrs \\ %{}) do
    %UserWordle{}
    |> UserWordle.changeset(attrs)
    |> Repo.insert()
  end

  def update_user_wordle(%UserWordle{} = user_wordle, attrs) do
    user_wordle
    |> UserWordle.changeset(attrs)
    |> Repo.update()
  end

  def change_user_wordle(%UserWordle{} = user_wordle, attrs \\ %{}) do
    UserWordle.changeset(user_wordle, attrs)
  end

  def get_or_create_user_wordle(user_id, multi_wordle_id) do
    case get_user_wordle(user_id, multi_wordle_id) do
      nil ->
        create_user_wordle(%{
          user_id: user_id,
          multi_wordle_id: multi_wordle_id,
          entered_words: [],
          attempts: 0,
          status: "playing"
        })

      user_wordle ->
        {:ok, user_wordle}
    end
  end

  def get_or_create_today_wordle do
    today = Date.utc_today()

    case get_multi_wordle_by_date(today) do
      nil ->
        {:ok, multi_wordle} =
          create_multi_wordle(%{
            word: pick_word(),
            date: today
          })

        multi_wordle

      multi_wordle ->
        multi_wordle
    end
  end

  # def add_user_guess(%UserWordle{} = user_wordle, guess) do
  #   updated_guesses = user_wordle.entered_words ++ [guess]

  #   update_user_wordle(user_wordle, %{
  #     entered_words: updated_guesses,
  #     attempts: user_wordle.attempts + 1
  #   })
  # end

  defp pick_word do
    Words.get_word()
  end
end
