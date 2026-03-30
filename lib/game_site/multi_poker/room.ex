defmodule GameSite.MultiPoker.Room do
  use GenServer

  alias GameSite.MultiPoker.{Player, GameLogic}

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

      # game state
      phase: Keyword.get(opts, :phase, :pre_flop),
      deck: Keyword.get(opts, :deck, []),
      community_cards: Keyword.get(opts, :community_cards, []),

      # blinds
      small_blind: Keyword.get(opts, :small_blind, 10),
      big_blind: Keyword.get(opts, :big_blind, 20),

      # flow
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
    GenServer.start_link(
      __MODULE__,
      attrs,
      name: via(room_id)
    )
  end

  def update_room(pid, opts) do
    GenServer.cast(pid, {:update_room, opts})
  end

  def start_hand(pid) do
    GenServer.cast(pid, :start_hand)
  end

  def player_fold(pid, player_id) do
    GenServer.cast(pid, {:player_fold, player_id})
  end

  def advance_phase_and_deal(pid) do
    GenServer.cast(pid, :advance_phase_and_deal)
  end

  def player_bet(pid, player_id, amount) do
    GenServer.cast(pid, {:player_bet, player_id, amount})
  end

  def add_player(pid, %Player{} = player) do
    GenServer.cast(pid, {:add_player, player})
  end

  def remove_player(pid, %Player{} = player) do
    GenServer.cast(pid, {:remove_player, player})
  end

  def update_player(pid, player_id, opts) do
    GenServer.cast(pid, {:update_player, player_id, opts})
  end

  def update_status(pid, status) do
    GenServer.cast(pid, {:update_status, status})
  end

  def get_state(pid) do
    GenServer.call(pid, :get_room_state)
  end

  @impl true
  def init(%{host: host, room_id: room_id}) do
    initial_state = new(host, room_id: room_id)
    {:ok, initial_state}
  end

  @impl true
  def handle_cast({:player_fold, player_id}, %__MODULE__{} = state) do
    {:noreply, GameLogic.player_fold(state, player_id)}
  end

  @impl true
  def handle_cast({:update_room, opts}, %__MODULE__{} = state) do
    {:noreply, change(state, opts)}
  end

  @impl true
  def handle_cast(:advance_phase_and_deal, %__MODULE__{} = state) do
    {:noreply, GameLogic.advance_phase_and_deal(state)}
  end

  def handle_cast({:player_bet, player_id, amount}, state) do
    {:noreply, GameLogic.player_bet(state, player_id, amount)}
  end

  @impl true
  def handle_cast(:start_hand, state) do
    {:noreply, GameLogic.start_hand(state)}
  end

  @impl true
  def handle_cast({:add_player, %Player{} = player}, %__MODULE__{players: players} = state) do
    new_players = Map.put(players, player.player_id, player)
    {:noreply, %__MODULE__{state | players: new_players}}
  end

  @impl true
  def handle_cast({:update_status, status}, state) do
    {:noreply, %__MODULE__{state | room_status: status}}
  end

  @impl true
  def handle_cast({:remove_player, %Player{} = player}, %__MODULE__{players: players} = state) do
    new_players = Map.delete(players, player.player_id)
    {:noreply, %__MODULE__{state | players: new_players}}
  end

  @impl true
  def handle_cast({:update_player, player_id, opts}, %__MODULE__{players: players} = state) do
    new_players =
      case Map.fetch(players, player_id) do
        {:ok, player} ->
          updated_player = Player.change(player, opts)
          Map.put(players, player_id, updated_player)

        :error ->
          players
      end

    {:noreply, %__MODULE__{state | players: new_players}}
  end

  @impl true
  def handle_call(:get_room_state, _from, state) do
    {:reply, state, state}
  end

  defp via(room_id) do
    {:via, Registry, {GameSite.MultiPoker.RoomRegistry, room_id}}
  end
end
