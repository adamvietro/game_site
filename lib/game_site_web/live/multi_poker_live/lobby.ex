defmodule GameSiteWeb.MultiPokerLive.Lobby do
  use GameSiteWeb, :live_view

  alias GameSite.MultiPoker.Room
  alias GameSite.MultiPoker
  alias GameSiteWeb.MultiPokerLive.Component

  @registry GameSite.MultiPoker.RoomRegistry

  @impl true
  def render(assigns) do
    ~H"""
    <Component.instructions />
    <Component.live_games rooms={@rooms} />
    <Component.new_game current_user={@current_user} />
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    rooms =
      if connected?(socket) do
        list_room_summaries()
      else
        []
      end

    {:ok, assign(socket, :rooms, rooms)}
  end

  @impl true
  def handle_event("create_room", _params, socket) do
    current_user = socket.assigns.current_user
    {_, room_id} = MultiPoker.create_room(current_user.id)

    socket =
      assign(socket, :rooms, list_room_summaries())

    {:noreply, redirect(socket, to: "/multi-poker/#{room_id}")}
  end

  defp list_rooms do
    Registry.select(@registry, [
      {
        {:"$1", :"$2", :"$3"},
        [],
        [{{:"$1", :"$2"}}]
      }
    ])
  end

  defp list_room_summaries do
    list_rooms()
    |> Enum.with_index(1)
    |> Enum.map(fn {{room_id, pid}, display_id} ->
      state = Room.get_state(pid)

      %{
        room_id: room_id,
        player_count: map_size(state.players),
        room_status: state.room_status,
        display_id: display_id
      }
    end)
  end
end
