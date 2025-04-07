defmodule GameSiteWeb.ScoreLive.Show do
  use GameSiteWeb, :live_view

  alias GameSite.Scores

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:score, Scores.get_score!(id))}
  end

  defp page_title(:show), do: "Show Score"
  defp page_title(:edit), do: "Edit Score"
end
