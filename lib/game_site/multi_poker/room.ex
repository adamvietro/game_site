defmodule GameSite.MultiPoker.Room do
  use GenServer

  alias GameSite.MultiPoker.Player

  defstruct players: %{},
            room_id: nil,
            room_status: :waiting,
            host_id: nil,
            full: false

  def new(%Player{} = host, opts \\ []) do
    host_id = host.player_id
    room_id = Keyword.get(opts, :room_id)
    room_status = Keyword.get(opts, :room_status, :waiting)
    full = Keyword.get(opts, :full, false)

    %__MODULE__{
      players: %{host_id => host},
      room_id: room_id,
      room_status: room_status,
      host_id: host_id,
      full: full
    }
  end

  def add_player(pid, %Player{} = player) do
    GenServer.cast(pid, {:add_player, player})
  end

  def remove_player(pid, %Player{} = player) do
    GenServer.cast(pid, {:remove_player, player})
  end

  def update_status(pid, status) do
    GenServer.cast(pid, {:update_status, status})
  end

  def start_link(host, opts \\ []) do
    GenServer.start_link(__MODULE__, {host, opts})
  end

  @impl true
  def init({host, opts}) do
    initial_state = new(host, opts)
    {:ok, initial_state}
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
  def handle_cast({:full_room}, state) do
    {:noreply, %__MODULE__{state | full: true}}
  end

  @impl true
  def handle_cast({:has_room}, state) do
    {:noreply, %__MODULE__{state | full: false}}
  end
end
