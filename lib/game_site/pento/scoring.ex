defmodule GameSite.Pento.Scoring do
  def score(board) do
    completed = length(board.completed_pentos)

    raw_score =
      completed * base_points(board.board_type) -
        board.moves * move_penalty(board.board_type)

    max(raw_score, 0)
  end

  defp base_points(:tiny), do: 250
  defp base_points(:small), do: 500
  defp base_points(:medium), do: 750
  defp base_points(:default), do: 1_000
  defp base_points(:wide), do: 1_250
  defp base_points(:widest), do: 1_500
  defp base_points(:skew), do: 1_250
  defp base_points(:donut), do: 1_500
  defp base_points(:ball), do: 1_500
  defp base_points(_), do: 500

  defp move_penalty(:tiny), do: 1
  defp move_penalty(:small), do: 2
  defp move_penalty(:medium), do: 3
  defp move_penalty(:default), do: 4
  defp move_penalty(:wide), do: 5
  defp move_penalty(:widest), do: 6
  defp move_penalty(:skew), do: 5
  defp move_penalty(:donut), do: 6
  defp move_penalty(:ball), do: 6
  defp move_penalty(_), do: 2
end
