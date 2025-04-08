defmodule GameSiteWeb.ScoreLive.Index do
  use GameSiteWeb, :live_view

  alias GameSite.Scores
  alias GameSite.Scores.Score

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :scores, Scores.list_top_scores_per_user_per_game())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Score")
    |> assign(:score, Scores.get_score!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Score")
    |> assign(:score, %Score{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Scores")
    |> assign(:score, nil)
  end

  @impl true
  def handle_info({GameSiteWeb.ScoreLive.FormComponent, {:saved, score}}, socket) do
    {:noreply, stream_insert(socket, :scores, score)}
  end

  @impl true
  def handle_info({GameSiteWeb.ScoreLive.FormComponent, {:new, game}}, socket) do
    {:noreply, stream_insert(socket, :games, game, at: 0)}
  end

  @impl true
  def handle_info({GameSiteWeb.ScoreLive.FormComponent, {:edit, game}}, socket) do
    {:noreply, stream_insert(socket, :games, game)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    score = Scores.get_score!(id)
    {:ok, _} = Scores.delete_score(score)

    {:noreply, stream_delete(socket, :scores, score)}
  end
end
