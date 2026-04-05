defmodule GameSiteWeb.MultiPokerLive do
  use GameSiteWeb, :live_view

  alias GameSite.MultiPoker.{Room, PubSub}
  alias GameSite.MultiPoker
  alias GameSiteWeb.MultiPokerLive.GameBoard

  @impl true
  def render(assigns) do
    ~H"""
    <%= if @room == nil  do %>
      Room is loading...
    <% else %>
      <GameBoard.score_board
        phase={@room.phase}
        current_player_turn={@room.current_player_turn}
        pot={@room.pot}
        dealer_player_id={@room.dealer_player_id}
        current_round_max_bet={@room.current_round_max_bet}
      />

      <GameBoard.game_table
        players={@room.players}
        current_player_turn={@room.current_player_turn}
        community_cards={@room.community_cards}
        current_viewer_id={@current_viewer_id}
      />

      <GameBoard.player_actions
        room_status={@room.room_status}
        action_state={@viewer_state.action_state}
        player_chips={@viewer_state.player_chips}
        player_current_bet={@viewer_state.player_current_bet}
        bet_amount={get_current_min_bet_needed(@room, @current_viewer_id)}
      />

      <div column-2>
        <GameBoard.join_game viewer_state={@viewer_state} room_status={@room.room_status} />
        <GameBoard.player_ready game_state={@room.room_status} viewer_state={@viewer_state} />
      </div>
    <% end %>
    """
  end

  @impl true
  def mount(params, session, socket) do
    socket =
      socket
      |> set_current_viewer_id(session)

    if connected?(socket) do
      case MultiPoker.get_room(params["room"]) do
        {:ok, room} ->
          PubSub.subscribe_room(room.room_id)

          viewer_state = Room.viewer_state(room, socket.assigns.current_viewer_id)

          socket =
            socket
            |> assign(:room, room)
            |> assign(:viewer_state, viewer_state)
            |> assign(:form, to_form(%{}))

          {:ok, socket}

        :error ->
          socket =
            socket
            |> assign(:room, :bad_room)
            |> assign(:form, to_form(%{}))

          {:ok, socket}
      end
    else
      {:ok, assign(socket, :room, nil)}
    end
  end

  @impl true
  def handle_info({:room_updated, room}, socket) do
    viewer_state = Room.viewer_state(room, socket.assigns.current_viewer_id)

    {:noreply,
     socket
     |> assign(room: room)
     |> assign(:viewer_state, viewer_state)}
  end

  @impl true
  def handle_info({:room_closed, _room_id}, socket) do
    {:noreply, push_navigate(socket, to: "/multi-poker")}
  end

  @impl true
  def handle_event(
        "player-ready",
        _params,
        %{assigns: %{current_viewer_id: viewer_id, room: %Room{room_id: room_id}}} = socket
      ) do
    MultiPoker.player_ready(room_id, viewer_id)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "player-bet",
        %{"bet_amount" => bet_amount},
        %{assigns: %{current_viewer_id: viewer_id, room: %Room{room_id: room_id}}} = socket
      ) do
    amount = String.to_integer(bet_amount)
    MultiPoker.player_bet(room_id, viewer_id, amount)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "join-game",
        _params,
        %{assigns: %{current_viewer_id: viewer_id, room: %Room{room_id: room_id}}} = socket
      ) do
    MultiPoker.add_player(room_id, viewer_id)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "player-fold",
        _params,
        %{assigns: %{current_viewer_id: viewer_id, room: %Room{room_id: room_id}}} = socket
      ) do
    MultiPoker.player_fold(room_id, viewer_id)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "player-check",
        _params,
        %{assigns: %{current_viewer_id: viewer_id, room: %Room{room_id: room_id}}} = socket
      ) do
    MultiPoker.player_check(room_id, viewer_id)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "player-all-in",
        _params,
        %{assigns: %{current_viewer_id: viewer_id, room: %Room{room_id: room_id}}} = socket
      ) do
    MultiPoker.player_all_in(room_id, viewer_id)

    {:noreply, socket}
  end

  def handle_event(
        "leave-game",
        _params,
        %{assigns: %{current_viewer_id: viewer_id, room: %Room{room_id: room_id}}} = socket
      ) do
    MultiPoker.player_leave_game(room_id, viewer_id)

    {:noreply, socket}
  end

  def set_current_viewer_id(%{assigns: %{current_user: current_user}} = socket, _session)
      when not is_nil(current_user) do
    assign(socket, :current_viewer_id, "user:#{current_user.id}")
  end

  def set_current_viewer_id(socket, session) do
    assign(socket, :current_viewer_id, "guest:#{session["guest_id"]}")
  end

  defp get_current_min_bet_needed(
         %Room{current_round_max_bet: current_round_max_bet} = room,
         viewer_id
       ) do
    case Room.get_player_by_viewer_id_from_room(room, viewer_id) do
      nil ->
        0

      player ->
        max(current_round_max_bet - player.current_bet, 0)
    end
  end
end
