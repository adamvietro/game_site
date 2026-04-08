defmodule GameSiteWeb.GuessingLive.QuestionTest do
  use ExUnit.Case, async: true

  alias GameSite.Guessing.Question

  describe "get_new_answer/0" do
    test "returns a string number between 1 and 10" do
      answer = Question.get_new_answer()

      assert answer in Enum.map(1..10, &(&1))
    end
  end
end
