defmodule GameSite.Guessing.GameLogic do
  alias GameSite.Guessing.{Guess, Question}

  def new_game do
    Guess.new(answer: Question.get_new_answer())
  end

  def submit_guess(%Guess{} = game, params) do
    game =
      Guess.change(game,
        flash_type: nil,
        flash_msg: "",
        message: ""
      )

    guessed_number = parse_guess(params)
    wager = parse_wager(params, game.score)
    guessed_numbers = MapSet.put(game.guessed_numbers, guessed_number)

    cond do
      guessed_number == game.answer ->
        updated_score = game.score + wager
        highest_score = max(game.highest_score, updated_score)

        Guess.change(game,
          score: updated_score,
          highest_score: highest_score,
          attempt: 1,
          answer: Question.get_new_answer(),
          wager: min(wager, updated_score),
          guessed_numbers: MapSet.new(),
          message: "Correct!"
        )

      game.attempt < 5 ->
        Guess.change(game,
          attempt: game.attempt + 1,
          wager: wager,
          guessed_numbers: guessed_numbers
        )

      true ->
        updated_score = game.score - wager

        cond do
          updated_score <= 0 ->
            Guess.change(game,
              flash_type: :error,
              flash_msg: "Out of Points, resetting.",
              score: 10,
              attempt: 1,
              answer: Question.get_new_answer(),
              wager: 1,
              guessed_numbers: MapSet.new(),
              message: "Incorrect. The correct answer was #{game.answer}."
            )

          true ->
            Guess.change(game,
              score: updated_score,
              attempt: 1,
              answer: Question.get_new_answer(),
              wager: min(wager, updated_score),
              guessed_numbers: MapSet.new(),
              message: "Incorrect. The correct answer was #{game.answer}."
            )
        end
    end
  end

  def update_to_max_bet(%Guess{score: score} = guess) do
    %{guess | wager: score}
  end

  defp parse_guess(params) do
    params["guess"]
    |> String.to_integer()
  end

  defp parse_wager(params, score) do
    params["wager"]
    |> to_string()
    |> case do
      "" -> 1
      value -> String.to_integer(value)
    end
    |> max(1)
    |> min(score)
  end
end
