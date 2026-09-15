defmodule GameSiteWeb.PentoLive do
  use GameSiteWeb, :live_view

  alias GameSiteWeb.PentoLive.Board
  alias GameSite.Scores.ScoreHandler
  alias GameSite.Pento.Scoring
  alias GameSiteWeb.PentoLive.Component

  @impl true
  def mount(%{"puzzle" => puzzle}, _session, socket) do
    {:ok, assign(socket, puzzle: puzzle, complete: false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="mx-auto flex min-h-[100dvh] max-w-4xl flex-col px-2 py-2 sm:px-4 sm:py-4">
      <h1 class="mb-2 text-2xl font-heavy">Welcome to Pento!</h1>

      <div class="mb-2 flex items-center justify-between">
        <Component.help />
        <Component.give_up />
      </div>

      <%= if @complete do %>
        <Component.complete_modal puzzle={@puzzle} current_user={@current_user} />
      <% end %>

      <div id="game-container" phx-hook="Fireworks" />

      <div class="flex-1 overflow-hidden">
        <div class="h-full rounded-lg bg-white p-2 dark:bg-gray-800">
          <.live_component module={Board} puzzle={@puzzle} id="board-component" key={@complete} />
        </div>
      </div>
    </section>
    """
  end

  @impl true
  def handle_info({:flash, message}, socket) do
    {:noreply, put_flash(socket, :info, message)}
  end

  @impl true
  def handle_info({:board_complete, board}, socket) do
    {:noreply,
     socket
     |> assign(complete: true)
     |> assign(score: Scoring.score(board))
     |> push_event("fireworks", %{})
     |> put_flash(:info, "Congratulations! You've completed the board!")}
  end

  @impl true
  def handle_info(_, socket), do: {:noreply, socket}

  @impl true
  def handle_event("try_again", _, socket) do
    {:noreply, assign(socket, complete: false)}
  end

  @impl true
  def handle_event("exit", _params, socket) do
    attrs = %{
      "score" => socket.assigns.score,
      "game_id" => 6,
      "user_id" => socket.assigns.current_user.id
    }

    ScoreHandler.save_score(socket, attrs)

    {:noreply,
     socket
     |> push_navigate(to: ~p"/pento_choice")}
  end
end
