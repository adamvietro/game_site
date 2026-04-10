defmodule GameSite.Guessing.Question do
  use GameSiteWeb, :live_view

  def get_new_answer() do
    new_answer()
  end

  defp new_answer(), do: Enum.random(1..10)
end
