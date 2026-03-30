defmodule GameSite.MultiPoker.GameLogicTest do
  use ExUnit.Case, async: true

  alias GameSite.MultiPoker.{GameLogic, Player, Room}

  defp build_room_with_players() do
    host =
      Player.new(1)
      |> Player.change(seat_position: 0, chips: 1000)

    player_2 =
      Player.new(2)
      |> Player.change(seat_position: 1, chips: 1000)

    player_3 =
      Player.new(3)
      |> Player.change(seat_position: 2, chips: 1000)

    Room.new(host, room_id: "room-1")
    |> Room.change(
      players: %{
        1 => host,
        2 => player_2,
        3 => player_3
      },
      dealer_player_id: 1,
      current_player_turn: 2
    )
  end

  describe "start_hand/1" do
    test "resets room hand state, deals two cards to each player, and sets first turn" do
      room = build_room_with_players()

      updated_room = GameLogic.start_hand(room)

      assert updated_room.phase == :pre_flop
      assert updated_room.pot == 0
      assert updated_room.community_cards == []
      assert updated_room.current_hand_number == 1
      assert updated_room.dealer_player_id == 2
      assert updated_room.current_player_turn == 3

      assert map_size(updated_room.players) == 3

      Enum.each(updated_room.players, fn {_id, player} ->
        assert length(player.hand) == 2
        assert player.current_bet == 0
        assert player.folded? == false
        assert player.ready? == false
      end)

      assert length(updated_room.deck) == 52 - 6
    end
  end

  describe "advance_phase_and_deal/1" do
    test "pre_flop deals flop and changes phase to flop" do
      room =
        build_room_with_players()
        |> Room.change(
          phase: :pre_flop,
          deck: [
            {14, "spades"},
            {13, "hearts"},
            {12, "clubs"},
            {11, "diamonds"}
          ],
          community_cards: []
        )

      updated_room = GameLogic.advance_phase_and_deal(room)

      assert updated_room.phase == :flop

      assert updated_room.community_cards == [
               {14, "spades"},
               {13, "hearts"},
               {12, "clubs"}
             ]

      assert updated_room.deck == [{11, "diamonds"}]
    end

    test "flop deals one card and changes phase to turn" do
      room =
        build_room_with_players()
        |> Room.change(
          phase: :flop,
          deck: [{9, "spades"}, {8, "hearts"}],
          community_cards: [{14, "spades"}, {13, "hearts"}, {12, "clubs"}]
        )

      updated_room = GameLogic.advance_phase_and_deal(room)

      assert updated_room.phase == :turn

      assert updated_room.community_cards == [
               {14, "spades"},
               {13, "hearts"},
               {12, "clubs"},
               {9, "spades"}
             ]

      assert updated_room.deck == [{8, "hearts"}]
    end

    test "turn deals one card and changes phase to river" do
      room =
        build_room_with_players()
        |> Room.change(
          phase: :turn,
          deck: [{7, "clubs"}, {6, "diamonds"}],
          community_cards: [{14, "spades"}, {13, "hearts"}, {12, "clubs"}, {9, "spades"}]
        )

      updated_room = GameLogic.advance_phase_and_deal(room)

      assert updated_room.phase == :river

      assert updated_room.community_cards == [
               {14, "spades"},
               {13, "hearts"},
               {12, "clubs"},
               {9, "spades"},
               {7, "clubs"}
             ]

      assert updated_room.deck == [{6, "diamonds"}]
    end

    test "river changes phase to showdown without dealing more cards" do
      board = [
        {14, "spades"},
        {13, "hearts"},
        {12, "clubs"},
        {9, "spades"},
        {7, "clubs"}
      ]

      room =
        build_room_with_players()
        |> Room.change(
          phase: :river,
          deck: [{6, "diamonds"}],
          community_cards: board
        )

      updated_room = GameLogic.advance_phase_and_deal(room)

      assert updated_room.phase == :showdown
      assert updated_room.community_cards == board
      assert updated_room.deck == [{6, "diamonds"}]
    end
  end

  describe "player_bet/3" do
    test "current player can bet, chips go down, pot goes up, and turn advances" do
      room = build_room_with_players()

      updated_room = GameLogic.player_bet(room, 2, 50)

      assert updated_room.pot == 50
      assert updated_room.current_player_turn == 3
      assert updated_room.players[2].current_bet == 50
      assert updated_room.players[2].chips == 950
    end

    test "non-current player cannot bet" do
      room = build_room_with_players()

      updated_room = GameLogic.player_bet(room, 1, 50)

      assert updated_room == room
    end

    test "zero or negative bet does nothing" do
      room = build_room_with_players()

      assert GameLogic.player_bet(room, 2, 0) == room
      assert GameLogic.player_bet(room, 2, -10) == room
    end
  end

  describe "player_fold/2" do
    test "current player can fold and turn advances" do
      room = build_room_with_players()

      updated_room = GameLogic.player_fold(room, 2)

      assert updated_room.players[2].folded? == true
      assert updated_room.current_player_turn == 3
    end

    test "non-current player cannot fold" do
      room = build_room_with_players()

      updated_room = GameLogic.player_fold(room, 1)

      assert updated_room == room
    end

    test "advance skips folded players" do
      room =
        build_room_with_players()
        |> Room.change(
          current_player_turn: 2,
          players: %{
            1 => Player.new(1) |> Player.change(seat_position: 0, folded?: false, chips: 1000),
            2 => Player.new(2) |> Player.change(seat_position: 1, folded?: false, chips: 1000),
            3 => Player.new(3) |> Player.change(seat_position: 2, folded?: true, chips: 1000)
          }
        )

      updated_room = GameLogic.player_fold(room, 2)

      assert updated_room.current_player_turn == 1
      assert updated_room.players[2].folded? == true
    end
  end
end
