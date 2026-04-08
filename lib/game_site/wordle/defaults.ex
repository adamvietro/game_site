defmodule GameSite.Wordle.Defaults do
  @letters ~w(q w e r t y u i o p a s d f g h j k l z x c v b n m)
  @rows 6
  @cells 30

  def starting_board do
    0..(@cells - 1) |> Enum.into(%{}, &{&1, "bg-gray-100"})
  end

  def starting_entries do
    for row <- 1..@rows, into: %{}, do: {row_name(row), entry_template()}
  end

  def starting_keyboard do
    Enum.into(@letters, %{}, &{String.to_atom(&1), "bg-gray-100"})
  end

  defp row_name(1), do: :first
  defp row_name(2), do: :second
  defp row_name(3), do: :third
  defp row_name(4), do: :fourth
  defp row_name(5), do: :fifth
  defp row_name(6), do: :sixth

  defp entry_template, do: %{l1: ".", l2: ".", l3: ".", l4: ".", l5: "."}
end
