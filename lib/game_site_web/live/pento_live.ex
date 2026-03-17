defmodule GameSiteWeb.PentoLive do
  use GameSiteWeb, :live_view

  alias GameSiteWeb.PentoLive.Board
  alias GameSiteWeb.GameInstructions
  alias GameSite.Scores.ScoreHandler

  @impl true
  def mount(%{"puzzle" => puzzle}, _session, socket) do
    {:ok, assign(socket, puzzle: puzzle, complete: false)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="mx-auto max-w-4xl px-4 py-8">
      <h1 class="font-heavy text-3xl mb-6">Welcome to Pento!</h1>
      <GameInstructions.show />
      <div class="flex justify-between items-center">
        <.help /> <.give_up />
      </div>
      <%= if @complete do %>
        <.complete_modal puzzle={@puzzle} />
      <% end %>
      <div id="game-container" phx-hook="Fireworks" />
      <.live_component module={Board} puzzle={@puzzle} id="board-component" key={@complete} />
    </section>
    """
  end

  @impl true
  def handle_info({:flash, message}, socket) do
    {:noreply, put_flash(socket, :info, message)}
  end

  @impl true
  def handle_info(:board_complete, socket) do
    {:noreply,
     socket
     |> assign(complete: true)
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
      "score" => 1,
      "game_id" => 6,
      "user_id" => socket.assigns.current_user.id
    }

    ScoreHandler.save_score(socket, attrs)

    {:noreply,
     socket
     |> push_navigate(to: ~p"/pento_choice")}
  end

  def complete_modal(assigns) do
    ~H"""
    <div class="fixed inset-0 bg-black bg-opacity-60 flex items-center justify-center z-50">
      <div class="bg-white rounded-2xl shadow-2xl p-8 flex flex-col items-center gap-6 max-w-sm w-full">
        <h2 class="text-2xl font-bold text-gray-800">🎉 Puzzle Complete!</h2>
        <p class="text-gray-500 text-center">Amazing work! What would you like to do next?</p>
        <div class="flex gap-4 w-full">
          <button
            phx-click="try_again"
            class="flex-1 py-3 rounded-xl bg-indigo-600 text-white font-semibold hover:bg-indigo-700 transition"
          >
            Try Again
          </button>
          <button
            phx-click="exit"
            class="flex-1 py-3 rounded-xl bg-indigo-600 text-white font-semibold hover:bg-indigo-700 transition"
          >
            Exit
          </button>
          <.link
            navigate={~p"/pento_choice"}
            class="flex-1 py-3 rounded-xl bg-gray-200 text-gray-800 font-semibold hover:bg-gray-300 transition text-center"
          >
            Pick a Puzzle
          </.link>
        </div>
      </div>
    </div>
    """
  end

  def help(assigns) do
    ~H"""
    <div class="relative">
      <.help_button />
      <.help_page />
    </div>
    """
  end

  attr(:class, :string, default: "h-8 w-8 text-slate hover:text-slate-400")

  def help_button(assigns) do
    ~H"""
    <button
      phx-click={JS.toggle(to: "#info", in: "fade-in", out: "fade-out")}
      class="text-slate hover:text-slate-400"
    >
      <.icon name="hero-question-mark-circle-solid" class="h-8 w-8" />
    </button>
    """
  end

  def help_page(assigns) do
    ~H"""
    <div
      id="info"
      class="absolute left-0 bottom-10 bg-base-100 border-2 border-base-300 text-base-content
    p-4 z-10 w-80 shadow-lg rounded hidden"
    >
      <ul class="list-disc list-inside">
        <li>Click on a pento to pick it up</li>
        <li>Drop a pento with a space</li>
        <li>Pentos can't overlap</li>
        <li>Pentos must be fully on the board</li>
        <li>Rotate a pento with shift</li>
        <li>Flip a pento with enter</li>
        <li>Place all the pentos to win</li>
      </ul>
    </div>
    """
  end

  def give_up(assigns) do
    ~H"""
    <.link navigate={~p"/pento_choice"} data-confirm="Are you sure you want to give up?">
      Give Up?
    </.link>
    """
  end
end
