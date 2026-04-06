defmodule GameSite.MultiPoker.Room do
  use GenServer

  alias GameSite.MultiPoker.{GameLogic, Player, PubSub}

  defstruct players: %{},
            room_id: nil,
            room_status: :waiting,
            host_id: nil,
            max_players: 6,
            phase: :pre_flop,
            deck: [],
            community_cards: [],
            small_blind: 50,
            big_blind: 100,
            current_player_turn: nil,
            pot: 0,
            current_hand_number: 0,
            dealer_player_id: nil,
            current_round_max_bet: 0,
            winning_hand: nil

  @allowed_keys [
    :players,
    :room_id,
    :room_status,
    :host_id,
    :max_players,
    :phase,
    :deck,
    :community_cards,
    :small_blind,
    :big_blind,
    :current_player_turn,
    :pot,
    :current_hand_number,
    :dealer_player_id,
    :current_round_max_bet,
    :winning_hand
  ]

  def new(%Player{} = host, opts \\ []) do
    host_id = host.player_id

    %__MODULE__{
      players: %{host_id => host},
      room_id: Keyword.get(opts, :room_id),
      room_status: Keyword.get(opts, :room_status, :waiting),
      host_id: host_id,
      max_players: Keyword.get(opts, :max_players, 6),
      phase: Keyword.get(opts, :phase, :pre_flop),
      deck: Keyword.get(opts, :deck, []),
      community_cards: Keyword.get(opts, :community_cards, []),
      small_blind: Keyword.get(opts, :small_blind, 50),
      big_blind: Keyword.get(opts, :big_blind, 100),
      current_player_turn: Keyword.get(opts, :current_player_turn, host_id),
      pot: Keyword.get(opts, :pot, 0),
      current_hand_number: Keyword.get(opts, :current_hand_number, 0),
      dealer_player_id: Keyword.get(opts, :dealer_player_id, host_id),
      current_round_max_bet: Keyword.get(opts, :current_round_max_bet, 0),
      winning_hand: Keyword.get(opts, :winning_hand, nil)
    }
  end

  def change(%__MODULE__{} = room, opts) do
    valid_opts =
      Enum.filter(opts, fn {key, _value} ->
        key in @allowed_keys
      end)

    struct(room, valid_opts)
  end

  def start_link(%{room_id: room_id} = attrs) do
    GenServer.start_link(__MODULE__, attrs, name: via(room_id))
  end

  # room/system actions

  def update_room(pid, opts) do
    GenServer.cast(pid, {:update_room, opts})
  end

  def start_hand(pid) do
    GenServer.cast(pid, :start_hand)
  end

  def advance_phase_and_deal(pid) do
    GenServer.cast(pid, :advance_phase_and_deal)
  end

  def update_status(pid, status) do
    GenServer.cast(pid, {:update_status, status})
  end

  def get_state(pid) do
    GenServer.call(pid, :get_room_state)
  end

  def get_player_by_viewer_id(pid, viewer_id) do
    GenServer.call(pid, {:get_player_by_viewer_id, viewer_id})
  end

  # viewer-facing actions

  def player_ready(pid, viewer_id) do
    GenServer.cast(pid, {:player_ready, viewer_id})
  end

  def player_add(pid, viewer_id) do
    GenServer.call(pid, {:player_add, viewer_id})
  end

  def player_check(pid, viewer_id) do
    GenServer.cast(pid, {:player_check, viewer_id})
  end

  def player_fold(pid, viewer_id) do
    GenServer.cast(pid, {:player_fold, viewer_id})
  end

  def player_bet(pid, viewer_id, amount) do
    GenServer.cast(pid, {:player_bet, viewer_id, amount})
  end

  def player_all_in(pid, viewer_id) do
    GenServer.cast(pid, {:player_all_in, viewer_id})
  end

  def player_leave_game(pid, viewer_id) do
    GenServer.cast(pid, {:remove_player, viewer_id})
  end

  def update_player(pid, viewer_id, opts) do
    GenServer.cast(pid, {:update_player, viewer_id, opts})
  end

  @impl true
  def init(%{host: host, room_id: room_id}) do
    {:ok, new(host, room_id: room_id)}
  end

  @impl true
  def handle_cast({:update_room, opts}, %__MODULE__{} = state) do
    {:noreply, change(state, opts)}
  end

  @impl true
  def handle_cast(:start_hand, %__MODULE__{} = state) do
    new_state = GameLogic.start_hand(state)
    PubSub.broadcast_room_updated(new_state)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:advance_phase_and_deal, %__MODULE__{} = state) do
    new_state = GameLogic.advance_phase_and_deal(state)
    PubSub.broadcast_room_updated(new_state)
    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:update_status, status}, %__MODULE__{} = state) do
    {:noreply, %__MODULE__{state | room_status: status}}
  end

  @impl true
  def handle_cast({:player_ready, viewer_id}, state) do
    case find_player_id_by_viewer_id(state, viewer_id) do
      nil ->
        {:noreply, state}

      player_id ->
        new_state =
          state
          |> GameLogic.mark_player_ready(player_id)
          |> GameLogic.maybe_start_hand()

        if new_state != state, do: PubSub.broadcast_room_updated(new_state)

        {:noreply, new_state}
    end
  end

  @impl true
  def handle_cast({:player_fold, viewer_id}, %__MODULE__{} = state) do
    case find_player_id_by_viewer_id(state, viewer_id) do
      nil ->
        {:noreply, state}

      player_id ->
        new_state = GameLogic.player_fold(state, player_id)

        if new_state != state, do: PubSub.broadcast_room_updated(new_state)

        {:noreply, new_state}
    end
  end

  @impl true
  def handle_cast({:player_bet, viewer_id, amount}, %__MODULE__{} = state) do
    case find_player_id_by_viewer_id(state, viewer_id) do
      nil ->
        {:noreply, state}

      player_id ->
        new_state = GameLogic.player_bet(state, player_id, amount)

        if new_state != state, do: PubSub.broadcast_room_updated(new_state)

        {:noreply, new_state}
    end
  end

  @impl true
  def handle_cast({:player_check, viewer_id}, %__MODULE__{} = state) do
    case find_player_id_by_viewer_id(state, viewer_id) do
      nil ->
        {:noreply, state}

      player_id ->
        new_state = GameLogic.player_check(state, player_id)

        if new_state != state, do: PubSub.broadcast_room_updated(new_state)

        {:noreply, new_state}
    end
  end

  @impl true
  def handle_cast({:player_all_in, viewer_id}, %__MODULE__{} = state) do
    case find_player_id_by_viewer_id(state, viewer_id) do
      nil ->
        {:noreply, state}

      player_id ->
        new_state = GameLogic.player_all_in(state, player_id)

        if new_state != state, do: PubSub.broadcast_room_updated(new_state)

        {:noreply, new_state}
    end
  end

  @impl true
  def handle_cast({:remove_player, viewer_id}, %__MODULE__{} = state) do
    case find_player_id_by_viewer_id(state, viewer_id) do
      nil ->
        {:noreply, state}

      player_id ->
        if player_id == state.host_id do
          PubSub.broadcast_room_closed(state.room_id)
          PubSub.broadcast_lobby_updated()

          {:stop, :normal, state}
        else
          new_state =
            state
            |> remove_player(player_id)
            |> maybe_advance_turn(player_id)

          if new_state != state do
            PubSub.broadcast_room_updated(new_state)
          end

          {:noreply, new_state}
        end
    end
  end

  @impl true
  def handle_cast({:update_player, viewer_id, opts}, %__MODULE__{} = state) do
    case find_player_id_by_viewer_id(state, viewer_id) do
      nil ->
        {:noreply, state}

      player_id ->
        new_players =
          case Map.fetch(state.players, player_id) do
            {:ok, player} ->
              updated_player = Player.change(player, opts)
              Map.put(state.players, player_id, updated_player)

            :error ->
              state.players
          end

        {:noreply, %__MODULE__{state | players: new_players}}
    end
  end

  @impl true
  def handle_call(:get_room_state, _from, %__MODULE__{} = state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:get_player_by_viewer_id, viewer_id}, _from, %__MODULE__{} = state) do
    player =
      state.players
      |> Map.values()
      |> Enum.find(fn player -> player.viewer_id == viewer_id end)

    {:reply, player, state}
  end

  @impl true
  def handle_call({:player_add, viewer_id}, _from, %__MODULE__{} = state) do
    case find_player_id_by_viewer_id(state, viewer_id) do
      nil ->
        case next_player_id(state) do
          nil ->
            {:reply, {:error, :room_full}, state}

          player_id ->
            player = Player.new(player_id, viewer_id)
            new_players = Map.put(state.players, player_id, player)
            new_state = %__MODULE__{state | players: new_players}

            PubSub.broadcast_room_updated(new_state)

            {:reply, {:ok}, new_state}
        end

      player_id ->
        {:reply, {:ok, Map.fetch!(state.players, player_id)}, state}
    end
  end

  defp via(room_id) do
    {:via, Registry, {GameSite.MultiPoker.RoomRegistry, room_id}}
  end

  def viewer_state(%__MODULE__{} = room, current_viewer_id) do
    case get_player_by_viewer_id_from_room(room, current_viewer_id) do
      nil ->
        %{
          player_id: nil,
          action_state: :not_joined,
          player_chips: 0,
          player_current_bet: 0,
          ready?: false
        }

      %Player{} = player ->
        action_state =
          cond do
            player.folded? -> :folded
            player.chips == 0 -> :all_in
            room.current_player_turn == player.player_id -> :your_turn
            true -> :waiting
          end

        %{
          action_state: action_state,
          player_chips: player.chips,
          player_current_bet: player.current_bet,
          player_id: player.player_id,
          ready?: player.ready?
        }
    end
  end

  def get_player_by_viewer_id_from_room(%__MODULE__{} = room, viewer_id) do
    room.players
    |> Map.values()
    |> Enum.find(fn player -> player.viewer_id == viewer_id end)
  end

  defp find_player_id_by_viewer_id(%__MODULE__{} = state, viewer_id) do
    state.players
    |> Map.values()
    |> Enum.find_value(fn player ->
      if player.viewer_id == viewer_id, do: player.player_id
    end)
  end

  defp next_player_id(%__MODULE__{} = state) do
    used_ids = Map.keys(state.players)
    Enum.find(1..state.max_players, fn id -> id not in used_ids end)
  end

  defp remove_player(%__MODULE__{} = state, player_id) do
    new_players = Map.delete(state.players, player_id)
    %__MODULE__{state | players: new_players}
  end

  defp maybe_advance_turn(%__MODULE__{} = state, player_id) do
    if state.current_player_turn == player_id do
      GameLogic.advance_to_next_player(state)
    else
      state
    end
  end
end
