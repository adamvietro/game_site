defmodule GameSite.MultiPoker.RoomTest do
  use ExUnit.Case, async: true

  alias GameSite.MultiPoker.{Player, Room}

  setup do
    room_id = Ecto.UUID.generate()
    host = Player.new(1, 1)

    {:ok, pid} = start_supervised({Room, %{room_id: room_id, host: host}})

    %{pid: pid, room_id: room_id, host: host}
  end

  defp wait_for_cast(), do: Process.sleep(10)

  describe "initial state" do
    test "starts with host in room", %{pid: pid, room_id: room_id, host: host} do
      room = Room.get_state(pid)

      assert room.room_id == room_id
      assert room.host_id == host.player_id
      assert room.room_status == :waiting
      assert room.players[host.player_id] == host
      assert room.current_player_turn == host.player_id
      assert room.dealer_player_id == host.player_id
    end
  end

  describe "player_add/2" do
    test "adds a player by viewer_id", %{pid: pid} do
      assert :ok = Room.player_add(pid, 2)

      room = Room.get_state(pid)

      assert room.players[2] == Player.new(2, 2)
    end

    test "returns existing player if viewer already joined", %{pid: pid} do
      assert :ok = Room.player_add(pid, 2)

      assert {:ok, player} = Room.player_add(pid, 2)
      assert player == Player.new(2, 2)

      room = Room.get_state(pid)
      assert map_size(room.players) == 2
    end

    test "returns error when room is full", %{pid: pid} do
      Enum.each(2..6, fn viewer_id ->
        assert :ok = Room.player_add(pid, viewer_id)
      end)

      assert {:error, :room_full} = Room.player_add(pid, 7)
    end
  end

  describe "player_leave_game/2" do
    test "removes a non-host player by viewer_id", %{pid: pid} do
      assert :ok = Room.player_add(pid, 2)

      Room.player_leave_game(pid, 2)
      wait_for_cast()

      room = Room.get_state(pid)

      refute Map.has_key?(room.players, 2)
    end

    test "does nothing when viewer is not in room", %{pid: pid} do
      room = Room.get_state(pid)

      Room.player_leave_game(pid, 999)
      wait_for_cast()

      assert Room.get_state(pid) == room
    end

    test "stops the room when host leaves", %{pid: pid} do
      Room.player_leave_game(pid, 1)
      wait_for_cast()

      refute Process.alive?(pid)
    end

    test "advances the turn if the current player leaves", %{pid: pid} do
      assert :ok = Room.player_add(pid, 2)
      assert :ok = Room.player_add(pid, 3)

      Room.update_room(pid, current_player_turn: 2)
      wait_for_cast()

      Room.player_leave_game(pid, 2)
      wait_for_cast()

      room = Room.get_state(pid)

      assert room.current_player_turn == 1
      refute Map.has_key?(room.players, 2)
    end
  end

  describe "room updates" do
    test "update_status/2 changes room status", %{pid: pid} do
      Room.update_status(pid, :in_progress)
      wait_for_cast()

      room = Room.get_state(pid)

      assert room.room_status == :in_progress
    end

    test "update_room/2 updates room-level fields", %{pid: pid} do
      Room.update_room(pid, pot: 200, phase: :flop)
      wait_for_cast()

      room = Room.get_state(pid)

      assert room.pot == 200
      assert room.phase == :flop
    end

    test "update_player/3 updates one player using viewer_id", %{pid: pid} do
      assert :ok = Room.player_add(pid, 2)

      Room.update_player(pid, 2, ready?: true, chips: 900)
      wait_for_cast()

      room = Room.get_state(pid)

      assert room.players[2].ready? == true
      assert room.players[2].chips == 900
    end

    test "update_player/3 does nothing for missing viewer_id", %{pid: pid} do
      room = Room.get_state(pid)

      Room.update_player(pid, 999, ready?: true)
      wait_for_cast()

      assert Room.get_state(pid) == room
    end
  end

  describe "game actions through the room process" do
    test "start_hand/1 runs game logic through the room process", %{pid: pid} do
      assert :ok = Room.player_add(pid, 2)

      Room.start_hand(pid)
      wait_for_cast()

      state = Room.get_state(pid)

      assert state.current_hand_number == 1
      assert state.phase == :pre_flop
      assert length(state.players[1].hand) == 2
      assert length(state.players[2].hand) == 2
      assert length(state.deck) == 48

      assert state.current_round_max_bet == state.big_blind
    end

    test "advance_phase_and_deal/1 advances phase", %{pid: pid} do
      Room.update_room(pid,
        phase: :pre_flop,
        deck: [{14, "spades"}, {13, "hearts"}, {12, "clubs"}, {11, "diamonds"}],
        community_cards: []
      )

      wait_for_cast()

      Room.advance_phase_and_deal(pid)
      wait_for_cast()

      state = Room.get_state(pid)

      assert state.phase == :flop

      assert state.community_cards == [
               {14, "spades"},
               {13, "hearts"},
               {12, "clubs"}
             ]

      assert state.deck == [{11, "diamonds"}]
    end

    test "player_bet/3 updates room through the process using viewer_id", %{pid: pid} do
      assert :ok = Room.player_add(pid, 2)

      Room.update_room(pid, current_player_turn: 1)
      wait_for_cast()

      Room.player_bet(pid, 1, 25)
      wait_for_cast()

      state = Room.get_state(pid)

      assert state.pot == 25
      assert state.players[1].current_bet == 25
      assert state.players[1].chips == 975
    end

    test "player_fold/2 updates fold state through the process using viewer_id", %{pid: pid} do
      assert :ok = Room.player_add(pid, 2)

      Room.update_room(pid, current_player_turn: 1)
      wait_for_cast()

      Room.player_fold(pid, 1)
      wait_for_cast()

      state = Room.get_state(pid)

      assert state.players[1].folded? == true
    end

    test "player_check/2 marks player waiting when valid", %{pid: pid} do
      assert :ok = Room.player_add(pid, 2)

      Room.update_room(pid, current_player_turn: 1, current_round_max_bet: 0)
      wait_for_cast()

      Room.player_check(pid, 1)
      wait_for_cast()

      state = Room.get_state(pid)

      assert state.players[1].waiting? == true
    end

    test "player_all_in/2 updates room through the process using viewer_id", %{pid: pid} do
      assert :ok = Room.player_add(pid, 2)

      Room.update_room(pid, current_player_turn: 1)
      wait_for_cast()

      Room.player_all_in(pid, 1)
      wait_for_cast()

      state = Room.get_state(pid)

      assert state.players[1].chips == 0
      assert state.players[1].current_bet == 1000
      assert state.players[1].total_contribution == 1000
    end

    test "player_ready/2 marks a player ready", %{pid: pid} do
      Room.player_ready(pid, 1)
      wait_for_cast()

      state = Room.get_state(pid)

      assert state.players[1].ready? == true
    end
  end

  describe "lookup helpers through the process" do
    test "get_player_by_viewer_id/2 returns matching player", %{pid: pid} do
      assert :ok = Room.player_add(pid, 2)

      assert Room.get_player_by_viewer_id(pid, 2) == Player.new(2, 2)
    end

    test "get_player_by_viewer_id/2 returns nil when missing", %{pid: pid} do
      assert Room.get_player_by_viewer_id(pid, 999) == nil
    end
  end

  describe "pure helper functions" do
    test "new/2 builds a room with defaults" do
      host = Player.new(1, 1)

      room = Room.new(host, room_id: "room-1")

      assert room.room_id == "room-1"
      assert room.host_id == 1
      assert room.players == %{1 => host}
      assert room.room_status == :waiting
      assert room.phase == :pre_flop
      assert room.small_blind == 50
      assert room.big_blind == 100
      assert room.current_player_turn == 1
      assert room.dealer_player_id == 1
    end

    test "change/2 only updates allowed keys" do
      host = Player.new(1, 1)
      room = Room.new(host, room_id: "room-1")

      updated =
        Room.change(room,
          pot: 300,
          phase: :turn,
          fake_key: "ignored"
        )

      assert updated.pot == 300
      assert updated.phase == :turn
      refute Map.has_key?(updated, :fake_key)
    end

    test "viewer_state/2 returns not_joined state when viewer is absent" do
      room = Room.new(Player.new(1, 1), room_id: "room-1")

      assert Room.viewer_state(room, 999) == %{
               player_id: nil,
               action_state: :not_joined,
               player_chips: 0,
               player_current_bet: 0,
               ready?: false,
               busted?: false
             }
    end

    test "viewer_state/2 returns your_turn for current player" do
      host = Player.new(1, 1)
      room = Room.new(host, room_id: "room-1")

      assert Room.viewer_state(room, 1) == %{
               action_state: :your_turn,
               player_chips: host.chips,
               player_current_bet: host.current_bet,
               player_id: host.player_id,
               ready?: host.ready?,
               busted?: host.busted?
             }
    end

    test "viewer_state/2 returns waiting for joined player not on turn" do
      host = Player.new(1, 1)

      player_2 =
        Player.new(2, 2)
        |> Player.change(chips: 900)

      room =
        Room.new(host, room_id: "room-1")
        |> Room.change(
          players: %{1 => host, 2 => player_2},
          current_player_turn: 1
        )

      state = Room.viewer_state(room, 2)

      assert state.action_state == :waiting
      assert state.player_id == 2
      assert state.player_chips == 900
    end

    test "viewer_state/2 returns folded for folded player" do
      host = Player.new(1, 1)

      folded_player =
        Player.new(2, 2)
        |> Player.change(folded?: true)

      room =
        Room.new(host, room_id: "room-1")
        |> Room.change(
          players: %{1 => host, 2 => folded_player},
          current_player_turn: 1
        )

      assert Room.viewer_state(room, 2).action_state == :folded
    end

    test "viewer_state/2 returns all_in for player with zero chips" do
      host = Player.new(1, 1)

      all_in_player =
        Player.new(2, 2)
        |> Player.change(chips: 0)

      room =
        Room.new(host, room_id: "room-1")
        |> Room.change(
          players: %{1 => host, 2 => all_in_player},
          current_player_turn: 1
        )

      assert Room.viewer_state(room, 2).action_state == :all_in
    end

    test "viewer_state/2 returns busted for busted player" do
      host = Player.new(1, 1)

      busted_player =
        Player.new(2, 2)
        |> Player.change(chips: 0, busted?: true)

      room =
        Room.new(host, room_id: "room-1")
        |> Room.change(
          players: %{1 => host, 2 => busted_player},
          current_player_turn: 1
        )

      assert Room.viewer_state(room, 2).action_state == :busted
    end

    test "get_player_by_viewer_id_from_room/2 returns player from room struct" do
      host = Player.new(1, 1)
      player_2 = Player.new(2, 2)

      room =
        Room.new(host, room_id: "room-1")
        |> Room.change(players: %{1 => host, 2 => player_2})

      assert Room.get_player_by_viewer_id_from_room(room, 2) == player_2
    end

    test "get_player_by_viewer_id_from_room/2 returns nil when missing" do
      room = Room.new(Player.new(1, 1), room_id: "room-1")

      assert Room.get_player_by_viewer_id_from_room(room, 999) == nil
    end
  end
end
