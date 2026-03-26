defmodule GameSiteWeb.GuessingLive.QuestionTest do
  use ExUnit.Case, async: true

  alias GameSiteWeb.Live.GuessingLive.Question

  describe "get_new_answer/0" do
    test "returns a string number between 1 and 10" do
      answer = Question.get_new_answer()

      assert answer in Enum.map(1..10, &Integer.to_string/1)
    end
  end

  describe "set_event_info/2" do
    test "updates score and marks correct when guess matches answer" do
      assigns = %{
        score: 100,
        highest_score: 150,
        attempt: 2,
        answer: "5"
      }

      params = %{
        "wager" => "10",
        "guess" => "5"
      }

      result = Question.set_event_info(assigns, params)

      assert result.wager == 10
      assert result.attempt == 2
      assert result.highest_score == 150
      assert result.correct == true

      # depends on what Helper.add_subtract_wager/3 returns
      # if correct guesses add the wager:
      assert result.current_score == 110
    end

    test "updates score and marks incorrect when guess does not match answer" do
      assigns = %{
        score: 100,
        highest_score: 150,
        attempt: 2,
        answer: "5"
      }

      params = %{
        "wager" => "10",
        "guess" => "3"
      }

      result = Question.set_event_info(assigns, params)

      assert result.wager == 10
      assert result.attempt == 2
      assert result.highest_score == 150
      assert result.correct == false

      # if incorrect guesses subtract the wager:
      assert result.current_score == 90
    end
  end
end
