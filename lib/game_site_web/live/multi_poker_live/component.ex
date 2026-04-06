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
    <.table id="rooms" rows={@rooms}>
      <:col :let={room} label="Room ID">
        <span class="font-mono text-sm">{room.display_id}</span>
      </:col>

      <:col :let={room} label="Players">
        {room.player_count}
      </:col>

      <:col :let={room} label="Status">
        <span class={[
          "inline-flex rounded-full px-2 py-1 text-xs font-semibold",
          room.room_status == :waiting && "bg-yellow-100 text-yellow-800",
          room.room_status == :in_progress && "bg-green-100 text-green-800"
        ]}>
          {room.room_status}
        </span>
      </:col>

      <:action :let={room}>
        <.link
          navigate={~p"/multi-poker/#{room.room_id}"}
          class="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white hover:bg-indigo-500"
        >
          Join
        </.link>
      </:action>
    </.table>
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
