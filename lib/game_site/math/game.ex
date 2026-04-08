defmodule GameSite.Math.Game do
  defstruct question: "Loading...",
            answer: nil,
            variables: nil,
            helper: %{},
            toggle: false,
            score: 10,
            highest_score: 0,
            wager: 1,
            message: nil,
            message_type: nil,
            flash_type: nil,
            flash_msg: ""

  @allowed_keys [
    :question,
    :answer,
    :variables,
    :helper,
    :toggle,
    :score,
    :highest_score,
    :wager,
    :message,
    :message_type,
    :flash_type,
    :flash_msg
  ]

  def new(opts \\ []) do
    opts
    |> Enum.filter(fn {key, _} -> key in @allowed_keys end)
    |> then(&struct(__MODULE__, &1))
  end

  def change(%__MODULE__{} = game, attrs) when is_list(attrs) do
    attrs
    |> Enum.filter(fn {key, _} -> key in @allowed_keys end)
    |> then(&struct(game, &1))
  end
end
