defmodule GameSiteWeb.MultiPokerLive.Lobby do
  use GameSiteWeb, :live_view

  alias GameSite.MultiPoker.{Room, PubSub}
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
  def mount(_params, session, socket) do
    socket =
      socket
      |> set_current_viewer_id(session)

    rooms =
      if connected?(socket) do
        PubSub.subscribe_lobby()
        list_room_summaries()
      else
        []
      end

    {:ok, assign(socket, :rooms, rooms)}
  end

  @impl true
  def handle_info({:lobby_updated}, socket) do
    rooms = list_room_summaries()

    {:noreply, assign(socket, :rooms, rooms)}
  end

  @impl true
  def handle_event("create_room", _params, socket) do
    current_viewer_id = socket.assigns.current_viewer_id

    {socket, room_id} =
      case MultiPoker.create_room(current_viewer_id) do
        {_, room_id} ->
          {socket, room_id}

        {:error, :already_has_room, room_id} ->
          socket =
            assign(socket, :rooms, list_room_summaries())

          {socket, room_id}
      end

    PubSub.broadcast_lobby_updated()

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

  def set_current_viewer_id(%{assigns: %{current_user: current_user}} = socket, _session)
      when not is_nil(current_user) do
    assign(socket, :current_viewer_id, "user:#{current_user.id}")
  end

  def set_current_viewer_id(socket, _session) do
    assign(socket, :current_viewer_id, :not_signed_in)
  end
end
