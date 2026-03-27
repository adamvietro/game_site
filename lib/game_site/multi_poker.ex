defmodule GameSite.MultiPoker do
  alias GameSite.MultiPoker.{Room, Player}

  @room_supervisor GameSite.MultiPoker.RoomSupervisor
  @registry GameSite.MultiPoker.RoomRegistry

  def create_room(user_id) do
    room_id = Ecto.UUID.generate()
    player = Player.new(user_id)

    case start_room(room_id, player) do
      {:ok, _pid} -> {:ok, room_id}
      {:error, reason} -> {:error, reason}
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

  defp start_room(room_id, host_player) do
    spec = %{
      id: room_id,
      start: {Room, :start_link, [host_player, [room_id: room_id]]}
    }

    DynamicSupervisor.start_child(@room_supervisor, spec)
  end
end
