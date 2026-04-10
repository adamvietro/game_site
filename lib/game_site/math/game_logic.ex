defmodule GameSite.Math.GameLogic do
  alias GameSite.Math.Game
  alias GameSite.Math.Question

  @starting_score 10
  @starting_wager 1
  @helper_start %{first: "", second: "", third: "", fourth: ""}

  def new_game(connected? \\ true) do
    if connected? do
      build_round(
        Game.new(score: @starting_score, highest_score: 0, wager: @starting_wager, toggle: true)
      )
    else
      Game.new(
        question: "Loading...",
        answer: nil,
        variables: nil,
        score: @starting_score,
        highest_score: 0,
        wager: @starting_wager,
        helper: @helper_start,
        toggle: false
      )
    end
  end

  def toggle_helper(%Game{} = game) do
    Game.change(game, toggle: !game.toggle)
  end

  def submit_answer(%Game{} = game, %{"guess" => guess, "wager" => wager}) do
    game =
      Game.change(game,
        message: nil,
        message_type: nil,
        flash_type: nil,
        flash_msg: ""
      )

    wager = wager_parse(wager)
    correct = correct?(guess, game.answer)

    new_score =
      if correct do
        game.score + wager
      else
        game.score - wager
      end

    cond do
      new_score <= 0 ->
        game
        |> Game.change(
          score: @starting_score,
          wager: @starting_wager,
          flash_type: :error,
          flash_msg: "Score is 0. Resetting."
        )
        |> build_round()

      correct ->
        game
        |> Game.change(
          score: new_score,
          highest_score: max(game.highest_score, new_score),
          wager: wager,
          message: "Correct!",
          message_type: :info
        )
        |> build_round()

      true ->
        game
        |> Game.change(
          score: new_score,
          highest_score: max(game.highest_score, new_score),
          wager: min(wager, max(new_score, 1)),
          message: "Incorrect.",
          message_type: :error
        )
        |> build_round()
    end
  end

  defp build_round(%Game{} = game) do
    question = Question.get_new_question()

    Game.change(game,
      question: question.question,
      answer: question.answer,
      variables: question.variables,
      helper: Question.get_helper(question.variables)
    )
  end

  def add_subtract_wager("", guess, answer) do
    if guess == to_string(answer) do
      1
    else
      -1
    end
  end

  def add_subtract_wager(wager, guess, answer) do
    if guess == to_string(answer) do
      String.to_integer(wager)
    else
      String.to_integer(wager) * -1
    end
  end

  def correct?(guess, answer) do
    guess == to_string(answer)
  end

  def wager_parse(wager) do
    if wager == "", do: 1, else: String.to_integer(wager)
  end
end
