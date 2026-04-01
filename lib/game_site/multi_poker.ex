defmodule GameSite.MultiPoker do
  alias GameSite.MultiPoker.{Player, Room}
  alias Ecto.UUID

  @room_supervisor GameSite.MultiPoker.RoomSupervisor
  @registry GameSite.MultiPoker.RoomRegistry

  def create_room(viewer_id) do
    case get_room_by_host(viewer_id) do
      {room_id, _pid} ->
        {:error, :already_has_room, room_id}

      nil ->
        room_id = UUID.generate()
        host_player = Player.new(1, viewer_id)

        case DynamicSupervisor.start_child(
               @room_supervisor,
               {Room, %{room_id: room_id, host: host_player}}
             ) do
          {:ok, _pid} -> {:ok, room_id}
          error -> error
        end
    end
  end

  def get_room_pid(room_id) do
    case Registry.lookup(@registry, room_id) do
      [{pid, _}] -> {:ok, pid}
      [] -> :error
    end
  end

  def get_room(room_id) do
    case get_room_pid(room_id) do
      {:ok, pid} -> {:ok, Room.get_state(pid)}
      :error -> :error
    end
  end

  def add_player(room_id, viewer_id) do
    with {:ok, pid} <- get_room_pid(room_id) do
      Room.add_player(pid, viewer_id)
    end
  end

  def player_bet(room_id, viewer_id, amount) do
    with {:ok, pid} <- get_room_pid(room_id) do
      Room.player_bet(pid, viewer_id, amount)
    end
  end

  def player_fold(room_id, viewer_id) do
    with {:ok, pid} <- get_room_pid(room_id) do
      Room.player_fold(pid, viewer_id)
    end
  end

  defp get_room_by_host(viewer_id) do
    Registry.select(@registry, [
      {
        {:"$1", :"$2", :"$3"},
        [],
        [{{:"$1", :"$2"}}]
      }
    ])
    |> Enum.find(fn {_room_id, pid} ->
      case Room.get_state(pid) do
        %{players: players} ->
          Enum.any?(Map.values(players), fn player ->
            player.viewer_id == viewer_id and player.player_id == 1
          end)

        _ ->
          false
      end
    end)
  end
end
