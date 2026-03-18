defmodule GameSiteWeb.Live.MathLive.Question do
  def get_helper(variables) do
    helper(variables)
  end

  def get_new_question() do
    new_question()
  end

  defp new_variables() do
    %{
      first: Enum.random(1..100),
      second: Enum.random(1..100),
      notation: Enum.random(["+", "-", "*"])
    }
  end

  defp get_answer(question) do
    {answer, _} = Code.eval_string(question)
    answer
  end

  defp question(%{first: first, second: second, notation: notation}) do
    "#{first} #{notation} #{second}"
  end

  defp new_question() do
    variables = new_variables()
    question = question(variables)
    answer = get_answer(question) |> to_string()
    %{variables: variables, question: question, answer: answer}
  end

  defp helper(variables) do
    first = tens_ones(variables.first)
    second = tens_ones(variables.second)
    notation = variables.notation

    case notation do
      "*" ->
        %{
          first: "#{first.tens} * #{second.tens} =",
          second: "#{first.tens} * #{second.ones} =",
          third: "#{second.tens} * #{first.ones} =",
          fourth: "#{second.ones} * #{first.ones} ="
        }

      "+" ->
        %{
          first: "#{first.tens} + #{second.tens} =",
          second: "#{first.ones} + #{second.ones} =",
          third: " ",
          fourth: " "
        }

      "-" ->
        if variables.first > variables.second do
          %{
            first: "#{first.tens} - #{second.tens} =",
            second: "#{first.ones} - #{second.ones} =",
            third: "If second ones > first ones, borrow from tens.",
            fourth: " "
          }
        else
          %{
            first: "#{second.tens} - #{first.tens} =",
            second: "#{second.ones} - #{first.ones} =",
            third: "If second ones > first ones, borrow from tens.",
            fourth: "Don't forget the sign."
          }
        end
    end
  end

  defp tens_ones(value), do: %{tens: div(value, 10) * 10, ones: rem(value, 10)}
end
