defmodule GameSite.MultiPoker.Room do
  use GenServer

  alias GameSite.MultiPoker.{GameLogic, Player}

  defstruct players: %{},
            room_id: nil,
            room_status: :waiting,
            host_id: nil,
            max_players: 6,
            phase: :pre_flop,
            deck: [],
            community_cards: [],
            small_blind: 10,
            big_blind: 20,
            current_player_turn: nil,
            pot: 0,
            current_hand_number: 0,
            dealer_player_id: nil

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
    :dealer_player_id
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
      small_blind: Keyword.get(opts, :small_blind, 10),
      big_blind: Keyword.get(opts, :big_blind, 20),
      current_player_turn: Keyword.get(opts, :current_player_turn, host_id),
      pot: Keyword.get(opts, :pot, 0),
      current_hand_number: Keyword.get(opts, :current_hand_number, 0),
      dealer_player_id: Keyword.get(opts, :dealer_player_id, host_id)
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

  # viewer-facing actions

  def add_player(pid, viewer_id) do
    GenServer.call(pid, {:add_player, viewer_id})
  end

  def player_fold(pid, viewer_id) do
    GenServer.cast(pid, {:player_fold, viewer_id})
  end

  def player_bet(pid, viewer_id, amount) do
    GenServer.cast(pid, {:player_bet, viewer_id, amount})
  end

  def remove_player(pid, viewer_id) do
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
  def handle_cast(:advance_phase_and_deal, %__MODULE__{} = state) do
    {:noreply, GameLogic.advance_phase_and_deal(state)}
  end

  @impl true
  def handle_cast(:start_hand, %__MODULE__{} = state) do
    {:noreply, GameLogic.start_hand(state)}
  end

  @impl true
  def handle_cast({:update_status, status}, %__MODULE__{} = state) do
    {:noreply, %__MODULE__{state | room_status: status}}
  end

  @impl true
  def handle_cast({:player_fold, viewer_id}, %__MODULE__{} = state) do
    case find_player_id_by_viewer_id(state, viewer_id) do
      nil ->
        {:noreply, state}

      player_id ->
        {:noreply, GameLogic.player_fold(state, player_id)}
    end
  end

  @impl true
  def handle_cast({:player_bet, viewer_id, amount}, %__MODULE__{} = state) do
    case find_player_id_by_viewer_id(state, viewer_id) do
      nil ->
        {:noreply, state}

      player_id ->
        {:noreply, GameLogic.player_bet(state, player_id, amount)}
    end
  end

  @impl true
  def handle_cast({:remove_player, viewer_id}, %__MODULE__{} = state) do
    case find_player_id_by_viewer_id(state, viewer_id) do
      nil ->
        {:noreply, state}

      player_id ->
        new_players = Map.delete(state.players, player_id)
        {:noreply, %__MODULE__{state | players: new_players}}
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
  def handle_call({:add_player, viewer_id}, _from, %__MODULE__{} = state) do
    case find_player_id_by_viewer_id(state, viewer_id) do
      nil ->
        case next_player_id(state) do
          nil ->
            {:reply, {:error, :room_full}, state}

          player_id ->
            player = Player.new(player_id, viewer_id)
            new_players = Map.put(state.players, player_id, player)

            {:reply, {:ok, player}, %__MODULE__{state | players: new_players}}
        end

      player_id ->
        {:reply, {:ok, Map.fetch!(state.players, player_id)}, state}
    end
  end

  defp via(room_id) do
    {:via, Registry, {GameSite.MultiPoker.RoomRegistry, room_id}}
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
end
