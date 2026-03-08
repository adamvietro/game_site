defmodule GameSite.Scores.ScoreHandler do
  use GameSiteWeb, :live_view

  import Phoenix.LiveView
  alias GameSite.Scores

  def save_score(socket, score_params) do
    case Scores.create_score(score_params) do
      {:ok, _score} ->
        {:noreply,
         socket
         |> put_flash(:info, "Score created successfully")
         |> push_navigate(to: "/scores")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}

      {:duplicate, :already_exists} ->
        {:noreply,
         socket
         |> put_flash(:info, "No new High Score")
         |> push_navigate(to: "/scores")}
    end
  end
end
