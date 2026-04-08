defmodule GameSiteWeb.MathLive.QuestionTest do
  use ExUnit.Case, async: true
  alias GameSite.Math.Question

  describe "get_new_question/0" do
    test "returns a map with variables, question, and answer" do
      result = Question.get_new_question()

      assert %{variables: variables, question: question, answer: answer} = result

      assert is_map(variables)
      assert is_binary(question)
      assert is_binary(answer)

      assert %{first: first, second: second, notation: notation} = variables
      assert first in 1..100
      assert second in 1..100
      assert notation in ["+", "-", "*"]
    end

    test "question string matches variables" do
      result = Question.get_new_question()

      %{variables: %{first: first, second: second, notation: notation}, question: question} =
        result

      assert question == "#{first} #{notation} #{second}"
    end

    test "answer matches evaluated question" do
      result = Question.get_new_question()

      %{question: question, answer: answer} = result

      {expected, _} = Code.eval_string(question)

      assert answer == to_string(expected)
    end
  end

  describe "get_helper/1 for multiplication" do
    test "returns multiplication breakdown" do
      variables = %{first: 23, second: 45, notation: "*"}

      assert Question.get_helper(variables) == %{
               first: "20 * 40 =",
               second: "20 * 5 =",
               third: "40 * 3 =",
               fourth: "5 * 3 ="
             }
    end
  end

  describe "get_helper/1 for addition" do
    test "returns addition breakdown" do
      variables = %{first: 23, second: 45, notation: "+"}

      assert Question.get_helper(variables) == %{
               first: "20 + 40 =",
               second: "3 + 5 =",
               third: " ",
               fourth: " "
             }
    end
  end

  describe "get_helper/1 for subtraction" do
    test "returns subtraction breakdown when first is greater than second" do
      variables = %{first: 78, second: 34, notation: "-"}

      assert Question.get_helper(variables) == %{
               first: "70 - 30 =",
               second: "8 - 4 =",
               third: "If second ones > first ones, borrow from tens.",
               fourth: " "
             }
    end

    test "returns reversed subtraction breakdown when second is greater than first" do
      variables = %{first: 34, second: 78, notation: "-"}

      assert Question.get_helper(variables) == %{
               first: "70 - 30 =",
               second: "8 - 4 =",
               third: "If second ones > first ones, borrow from tens.",
               fourth: "Don't forget the sign."
             }
    end
  end
end
