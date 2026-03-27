defmodule GameSite.MultiPoker.RoomTest do
  use ExUnit.Case, async: true

  alias GameSite.MultiPoker.{Player, Room}

  setup do
    room_id = Ecto.UUID.generate()
    host = Player.new(1)
    {:ok, pid} = Room.start_link(host, room_id: room_id)

    %{pid: pid, room_id: room_id, host: host}
  end

  test "starts with host in room", %{pid: pid, room_id: room_id, host: host} do
    room = Room.get_state(pid)

    assert room.room_id == room_id
    assert room.host_id == host.player_id
    assert room.room_status == :waiting
    assert room.players[host.player_id] == host
  end

  test "add_player/2 adds a player", %{pid: pid} do
    player = Player.new(2)

    :ok = Room.add_player(pid, player)
    Process.sleep(10)

    room = Room.get_state(pid)

    assert room.players[player.player_id] == player
  end

  test "remove_player/2 removes a player", %{pid: pid} do
    player = Player.new(2)

    :ok = Room.add_player(pid, player)
    Process.sleep(10)
    :ok = Room.remove_player(pid, player)
    Process.sleep(10)

    room = Room.get_state(pid)

    refute Map.has_key?(room.players, player.player_id)
  end

  test "update_status/2 changes room status", %{pid: pid} do
    :ok = Room.update_status(pid, :in_progress)
    Process.sleep(10)

    room = Room.get_state(pid)

    assert room.room_status == :in_progress
  end
end
