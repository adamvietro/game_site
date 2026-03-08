defmodule GameSite.Scores.ScoreComponents do
  use Phoenix.Component
  alias GameSite.Scores.Score

  attr(:score_params, Score, required: true)

  def save_score(assigns) do
    case Scores.create_score(@score_params) do
      {:ok, score} ->
        notify_parent({:new, score})

        {:noreply,
         socket |> put_flash(:info, "Score created successfully") |> push_navigate(to: "/scores")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}

      {:duplicate, :already_exists} ->
        {:noreply,
         socket |> put_flash(:info, "No new High Score") |> push_navigate(to: "/scores")}
    end
  end
end
