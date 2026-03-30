defmodule GameSite.MultiPoker.RoomTest do
  use ExUnit.Case, async: true

  alias GameSite.MultiPoker.{Player, Room}

  setup do
    room_id = Ecto.UUID.generate()
    host = Player.new(1)

    {:ok, pid} = Room.start_link(%{room_id: room_id, host: host})

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

  describe "basic room process behavior" do
    test "starts with host in players map" do
      {pid, host, room_id} = start_room()

      state = Room.get_state(pid)

      assert state.room_id == room_id
      assert state.host_id == host.player_id
      assert state.players[host.player_id].player_id == host.player_id
    end

    test "add_player/2 adds a player to the room" do
      {pid, _host, _room_id} = start_room()

      player =
        Player.new(2)
        |> Player.change(seat_position: 1, chips: 1000)

      Room.add_player(pid, player)

      state = Room.get_state(pid)

      assert state.players[2].player_id == 2
    end

    test "remove_player/2 removes a player from the room" do
      {pid, _host, _room_id} = start_room()

      player =
        Player.new(2)
        |> Player.change(seat_position: 1, chips: 1000)

      Room.add_player(pid, player)
      Room.remove_player(pid, player)

      state = Room.get_state(pid)

      refute Map.has_key?(state.players, 2)
    end

    test "update_player/3 updates one player inside the room" do
      {pid, _host, _room_id} = start_room()

      player =
        Player.new(2)
        |> Player.change(seat_position: 1, chips: 1000)

      Room.add_player(pid, player)
      Room.update_player(pid, 2, ready?: true, chips: 900)

      state = Room.get_state(pid)

      assert state.players[2].ready? == true
      assert state.players[2].chips == 900
    end

    test "update_room/2 updates room-level fields" do
      {pid, _host, _room_id} = start_room()

      Room.update_room(pid, pot: 200, phase: :flop)

      state = Room.get_state(pid)

      assert state.pot == 200
      assert state.phase == :flop
    end

    test "start_hand/1 runs game logic through the room process" do
      {pid, _host, _room_id} = start_room()

      player =
        Player.new(2)
        |> Player.change(seat_position: 1, chips: 1000)

      Room.add_player(pid, player)
      Room.start_hand(pid)

      state = Room.get_state(pid)

      assert state.current_hand_number == 1
      assert state.phase == :pre_flop
      assert length(state.players[1].hand) == 2
      assert length(state.players[2].hand) == 2
      assert length(state.deck) == 48
    end

    test "player_bet/3 updates room through the process" do
      {pid, _host, _room_id} = start_room()

      player =
        Player.new(2)
        |> Player.change(seat_position: 1, chips: 1000)

      Room.add_player(pid, player)
      Room.update_room(pid, current_player_turn: 1)

      Room.player_bet(pid, 1, 25)

      state = Room.get_state(pid)

      assert state.pot == 25
      assert state.players[1].current_bet == 25
      assert state.players[1].chips == 975
    end

    test "player_fold/2 updates fold state through the process" do
      {pid, _host, _room_id} = start_room()

      player =
        Player.new(2)
        |> Player.change(seat_position: 1, chips: 1000)

      Room.add_player(pid, player)
      Room.update_room(pid, current_player_turn: 1)

      Room.player_fold(pid, 1)

      state = Room.get_state(pid)

      assert state.players[1].folded? == true
    end
  end

  defp start_room() do
    host =
      Player.new(1)
      |> Player.change(chips: 1000)

    room_id = Ecto.UUID.generate()

    {:ok, pid} = start_supervised({Room, %{room_id: room_id, host: host}})
    {pid, host, room_id}
  end
end
