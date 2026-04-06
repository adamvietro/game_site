defmodule GameSite.MultiPokerTest do
  use ExUnit.Case, async: false

  alias GameSite.MultiPoker

  test "create_room/1 starts and registers a room" do
    {:ok, room_id} = MultiPoker.create_room(123)

    assert is_binary(room_id)

    assert {:ok, pid} = MultiPoker.get_room_pid(room_id)
    assert is_pid(pid)

    assert {:ok, room} = MultiPoker.get_room(room_id)
    assert room.room_id == room_id
    assert room.host_id == 1
    assert Map.has_key?(room.players, 1)
  end

  test "get_room_pid/1 returns :error for missing room" do
    assert :error = MultiPoker.get_room_pid(Ecto.UUID.generate())
  end

  test "get_room/1 returns :error for missing room" do
    assert :error = MultiPoker.get_room(Ecto.UUID.generate())
  end
end
