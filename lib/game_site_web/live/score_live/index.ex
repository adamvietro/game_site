defmodule GameSiteWeb.ScoreLive.Index do
  use GameSiteWeb, :live_view

  alias GameSite.Scores
  alias GameSite.Scores.Score
  alias GameSite.Games

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:filters, %{})
     |> assign(:games, Games.list_games())
     |> assign(:score, nil)
     |> stream(:scores, [])}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    scores = Scores.list_scores_filtered(params)

    socket =
      socket
      |> assign(:filters, params)
      |> stream(:scores, scores, reset: true)
      |> apply_action(socket.assigns.live_action, params)

    {:noreply, socket}
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

  @impl true
  def handle_event("filter", params, socket) do
    clean_params =
      params
      |> Enum.reject(fn {_key, value} -> value in ["", nil] end)
      |> Map.new()

    {:noreply,
     push_patch(socket,
       to: ~p"/scores?#{clean_params}"
     )}
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
end
