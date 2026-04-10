defmodule GameSiteWeb.MultiPokerLive.Component do
  use GameSiteWeb, :live_view
  use Phoenix.Component

  def instructions(assigns) do
    ~H"""
    <h2 class="text-xl font-semibold mb-2">Poker Game Overview</h2>
    <ul class="list-disc list-inside mt-2 space-y-1 text-gray-700">
      <li>Here you can create or join a room to play some poker</li>
      <li>You must be logged in to create a room.</li>
      <li>There will be a max of 6 players per room.</li>
      <li>You will start with 1000 chips if you are a new player.</li>
    </ul>
    """
  end

  attr(:rooms, :map, required: true)

  def live_games(assigns) do
    ~H"""
    <div class="space-y-3">
      <h2 class="text-lg font-semibold text-zinc-100">Live Games</h2>

      <%= if Enum.empty?(@rooms) do %>
        <div class="rounded-lg border border-zinc-800 bg-zinc-900 p-4 text-sm text-zinc-400">
          No live rooms right now.
        </div>
      <% else %>
        <div class="grid grid-cols-1 gap-3">
          <%= for room <- @rooms do %>
            <div class="rounded-xl border border-zinc-800 bg-zinc-900 p-4 shadow-sm">
              <div class="flex items-start justify-between gap-3">
                <div class="min-w-0">
                  <div class="text-xs uppercase tracking-wide text-zinc-500">Room</div>
                  <div class="font-mono text-sm text-zinc-100 break-all">
                    {room.display_id}
                  </div>
                </div>

                <span class={[
                  "inline-flex shrink-0 rounded-full px-2 py-1 text-xs font-semibold",
                  room.room_status == :waiting && "bg-amber-500/15 text-amber-400",
                  room.room_status == :in_progress && "bg-emerald-500/15 text-emerald-400"
                ]}>
                  {room.room_status}
                </span>
              </div>

              <div class="mt-3 flex items-center justify-between text-sm">
                <div>
                  <span class="text-zinc-500">Players</span>
                  <span class="ml-2 font-medium text-zinc-100">{room.player_count}</span>
                </div>

                <.link
                  navigate={~p"/multi-poker/#{room.room_id}"}
                  class="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white hover:bg-indigo-500 transition"
                >
                  Join
                </.link>
              </div>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  attr(:current_user, :map, required: false)

  def new_game(assigns) do
    ~H"""
    <div class="rounded-xl border border-zinc-200 bg-white p-6 shadow-sm">
      <h2 class="mb-2 text-xl font-semibold text-zinc-800">Can't find a game you like?</h2>

      <%= if @current_user == nil do %>
        <p class="mb-4 text-sm text-zinc-600">
          Log in or create an account to make your own room.
        </p>

        <div class="flex gap-3">
          <.link
            navigate={~p"/users/log_in"}
            class="rounded-md bg-indigo-600 px-4 py-2 text-sm font-semibold text-white hover:bg-indigo-500"
          >
            Log in
          </.link>

          <.link
            navigate={~p"/users/register"}
            class="rounded-md border border-zinc-300 px-4 py-2 text-sm font-semibold text-zinc-700 hover:bg-zinc-50"
          >
            Register
          </.link>
        </div>
      <% else %>
        <p class="mb-4 text-sm text-zinc-600">
          Start a new room and invite other players to join.
        </p>

        <button
          type="button"
          phx-click="create_room"
          class="rounded-md bg-emerald-600 px-4 py-2 text-sm font-semibold text-white hover:bg-emerald-500"
        >
          Create Room
        </button>
      <% end %>
    </div>
    """
  end
end
