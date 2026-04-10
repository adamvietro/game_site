defmodule GameSite.Guessing.Guess do
  defstruct flash_type: nil,
            flash_msg: "",
            score: 10,
            highest_score: 0,
            attempt: 1,
            answer: nil,
            wager: 1,
            guessed_numbers: MapSet.new(),
            message: ""

  @allowed_keys [
    :flash_type,
    :flash_msg,
    :score,
    :highest_score,
    :attempt,
    :answer,
    :wager,
    :guessed_numbers,
    :message
  ]

  def new(opts \\ []) do
    opts
    |> Enum.filter(fn {key, _} -> key in @allowed_keys end)
    |> then(&struct(__MODULE__, &1))
  end

  def change(%__MODULE__{} = guess, attrs) when is_list(attrs) do
    struct(guess, Enum.filter(attrs, fn {key, _} -> key in @allowed_keys end))
  end
end
