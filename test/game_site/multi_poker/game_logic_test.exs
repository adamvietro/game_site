defmodule GameSite.MultiPoker.GameLogicTest do
  use ExUnit.Case, async: true

  alias GameSite.MultiPoker.{GameLogic, Player, Room}

  defp build_room_with_players() do
    host =
      Player.new(1, 1)
      |> Player.change(seat_position: 0, chips: 1000)

    player_2 =
      Player.new(2, 2)
      |> Player.change(seat_position: 1, chips: 1000)

    player_3 =
      Player.new(3, 3)
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
    test "resets room hand state, posts blinds, deals two cards to each player, and sets first turn" do
      room = build_room_with_players()

      updated_room = GameLogic.start_hand(room)

      assert updated_room.phase == :pre_flop
      assert updated_room.pot == 0
      assert updated_room.community_cards == []
      assert updated_room.current_hand_number == 1
      assert updated_room.dealer_player_id == 2
      assert updated_room.current_player_turn == 3
      assert updated_room.current_round_max_bet == updated_room.big_blind

      assert map_size(updated_room.players) == 3

      player_1 = updated_room.players[1]
      player_2 = updated_room.players[2]
      player_3 = updated_room.players[3]

      Enum.each(updated_room.players, fn {_id, player} ->
        assert length(player.hand) == 2
        assert player.folded? == false
        assert player.ready? == false
        assert player.waiting? == false
      end)

      assert player_2.current_bet == 0
      assert player_2.total_contribution == 0
      assert player_2.chips == 1000

      assert player_3.current_bet == updated_room.small_blind
      assert player_3.total_contribution == updated_room.small_blind
      assert player_3.chips == 1000 - updated_room.small_blind

      assert player_1.current_bet == updated_room.big_blind
      assert player_1.total_contribution == updated_room.big_blind
      assert player_1.chips == 1000 - updated_room.big_blind

      assert length(updated_room.deck) == 52 - 6
    end
  end

  describe "advance_phase_and_deal/1" do
    test "pre_flop deals flop, resets round state, and sets first turn" do
      room =
        build_room_with_players()
        |> Room.change(
          phase: :pre_flop,
          current_round_max_bet: 100,
          deck: [
            {14, "spades"},
            {13, "hearts"},
            {12, "clubs"},
            {11, "diamonds"}
          ],
          community_cards: [],
          players: %{
            1 =>
              Player.new(1, 1)
              |> Player.change(
                seat_position: 0,
                current_bet: 100,
                waiting?: true,
                chips: 900
              ),
            2 =>
              Player.new(2, 2)
              |> Player.change(
                seat_position: 1,
                current_bet: 100,
                waiting?: true,
                chips: 900
              ),
            3 =>
              Player.new(3, 3)
              |> Player.change(
                seat_position: 2,
                current_bet: 100,
                waiting?: true,
                chips: 900
              )
          }
        )

      updated_room = GameLogic.advance_phase_and_deal(room)

      assert updated_room.phase == :flop

      assert updated_room.community_cards == [
               {14, "spades"},
               {13, "hearts"},
               {12, "clubs"}
             ]

      assert updated_room.deck == [{11, "diamonds"}]
      assert updated_room.current_round_max_bet == 0
      assert updated_room.current_player_turn == 2

      Enum.each(updated_room.players, fn {_id, player} ->
        assert player.current_bet == 0
        assert player.waiting? == false
      end)
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
      assert updated_room.current_player_turn == 2
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
      assert updated_room.current_player_turn == 2
    end

    test "river moves to showdown, awards pot, and ends the hand" do
      board = [
        {2, "spades"},
        {7, "hearts"},
        {9, "clubs"},
        {11, "diamonds"},
        {13, "spades"}
      ]

      room =
        build_room_with_players()
        |> Room.change(
          phase: :river,
          pot: 300,
          room_status: :playing,
          deck: [{6, "diamonds"}],
          community_cards: board,
          players: %{
            1 =>
              Player.new(1, 1)
              |> Player.change(
                seat_position: 0,
                chips: 1000,
                hand: [{14, "hearts"}, {14, "clubs"}],
                ready?: true
              ),
            2 =>
              Player.new(2, 2)
              |> Player.change(
                seat_position: 1,
                chips: 1000,
                hand: [{3, "hearts"}, {8, "clubs"}],
                ready?: true
              ),
            3 =>
              Player.new(3, 3)
              |> Player.change(
                seat_position: 2,
                chips: 1000,
                hand: [{4, "hearts"}, {6, "clubs"}],
                ready?: true
              )
          }
        )

      updated_room = GameLogic.advance_phase_and_deal(room)

      assert updated_room.phase == :showdown
      assert updated_room.room_status == :waiting
      assert updated_room.current_player_turn == nil
      assert updated_room.winning_player_id == 1
      assert updated_room.winning_hand != nil
      assert updated_room.players[1].chips == 1300

      Enum.each(updated_room.players, fn {_id, player} ->
        assert player.ready? == false
        assert player.busted? == false
      end)
    end
  end

  describe "player_bet/3" do
    test "current player can bet, chips go down, pot goes up, and turn advances" do
      room = build_room_with_players()

      updated_room = GameLogic.player_bet(room, 2, 50)

      assert updated_room.pot == 50
      assert updated_room.current_player_turn == 3
      assert updated_room.current_round_max_bet == 50
      assert updated_room.players[2].current_bet == 50
      assert updated_room.players[2].total_contribution == 50
      assert updated_room.players[2].chips == 950
      assert updated_room.players[2].waiting? == true
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

    test "player cannot bet more than their chips" do
      room = build_room_with_players()

      updated_room = GameLogic.player_bet(room, 2, 2000)

      assert updated_room == room
    end
  end

  describe "player_fold/2" do
    test "current player can fold and turn advances" do
      room = build_room_with_players()
      assert room.current_player_turn == 2

      updated_room = GameLogic.player_fold(room, 2)

      assert updated_room.players[2].folded? == true
      assert updated_room.players[2].waiting? == true
      assert updated_room.current_player_turn == 3
    end

    test "non-current player cannot fold" do
      room = build_room_with_players()

      updated_room = GameLogic.player_fold(room, 1)

      assert updated_room == room
    end

    test "folding down to one player ends the hand by fold" do
      room =
        build_room_with_players()
        |> Room.change(
          pot: 200,
          room_status: :playing,
          players: %{
            1 =>
              Player.new(1, 1)
              |> Player.change(
                seat_position: 0,
                chips: 1000,
                ready?: true,
                folded?: false
              ),
            2 =>
              Player.new(2, 2)
              |> Player.change(
                seat_position: 1,
                chips: 1000,
                ready?: true,
                folded?: false
              ),
            3 =>
              Player.new(3, 3)
              |> Player.change(
                seat_position: 2,
                chips: 1000,
                ready?: true,
                folded?: true
              )
          },
          current_player_turn: 2
        )

      updated_room = GameLogic.player_fold(room, 2)

      assert updated_room.room_status == :waiting
      assert updated_room.current_player_turn == nil
      assert updated_room.winning_player_id == 1
      assert updated_room.winning_hand == nil
      assert updated_room.players[1].chips == 1200
      assert updated_room.players[1].ready? == false
      assert updated_room.players[2].ready? == false
      assert updated_room.players[3].ready? == false
    end
  end

  describe "player_check/2" do
    test "current player can check when matched to the round max bet" do
      room =
        build_room_with_players()
        |> Room.change(
          current_round_max_bet: 50,
          players: %{
            1 =>
              Player.new(1, 1)
              |> Player.change(seat_position: 0, chips: 1000, current_bet: 50),
            2 =>
              Player.new(2, 2)
              |> Player.change(seat_position: 1, chips: 1000, current_bet: 50),
            3 =>
              Player.new(3, 3)
              |> Player.change(seat_position: 2, chips: 1000, current_bet: 50)
          }
        )

      updated_room = GameLogic.player_check(room, 2)

      assert updated_room.players[2].waiting? == true
      assert updated_room.current_player_turn == 3
    end

    test "player cannot check when behind the current round max bet" do
      room =
        build_room_with_players()
        |> Room.change(
          current_round_max_bet: 50,
          players: %{
            1 =>
              Player.new(1, 1)
              |> Player.change(seat_position: 0, chips: 1000, current_bet: 50),
            2 =>
              Player.new(2, 2)
              |> Player.change(seat_position: 1, chips: 1000, current_bet: 0),
            3 =>
              Player.new(3, 3)
              |> Player.change(seat_position: 2, chips: 1000, current_bet: 50)
          }
        )

      updated_room = GameLogic.player_check(room, 2)

      assert updated_room == room
    end

    test "non-current player cannot check" do
      room =
        build_room_with_players()
        |> Room.change(current_round_max_bet: 0)

      updated_room = GameLogic.player_check(room, 1)

      assert updated_room == room
    end
  end

  describe "player_all_in/2" do
    test "current player can go all in" do
      room = build_room_with_players()

      updated_room = GameLogic.player_all_in(room, 2)

      assert updated_room.players[2].chips == 0
      assert updated_room.players[2].current_bet == 1000
      assert updated_room.players[2].total_contribution == 1000
      assert updated_room.players[2].waiting? == true
      assert updated_room.pot == 1000
      assert updated_room.current_round_max_bet == 1000
      assert updated_room.current_player_turn == 3
    end

    test "non-current player cannot go all in" do
      room = build_room_with_players()

      updated_room = GameLogic.player_all_in(room, 1)

      assert updated_room == room
    end
  end

  describe "award_pot/3" do
    test "adds the pot to the winner and stores winner info" do
      room =
        build_room_with_players()
        |> Room.change(pot: 250)

      updated_room = GameLogic.award_pot(room, 2, "One Pair")

      assert updated_room.players[2].chips == 1250
      assert updated_room.winning_player_id == 2
      assert updated_room.winning_hand == "One Pair"
    end

    test "returns room unchanged when winner is missing" do
      room =
        build_room_with_players()
        |> Room.change(pot: 250)

      updated_room = GameLogic.award_pot(room, 999, "One Pair")

      assert updated_room == room
    end
  end

  describe "mark_player_ready/2" do
    test "marks a player as ready" do
      room = build_room_with_players()

      updated_room = GameLogic.mark_player_ready(room, 2)

      assert updated_room.players[2].ready? == true
      assert updated_room.players[1].ready? == false
      assert updated_room.players[3].ready? == false
    end

    test "does nothing when player does not exist" do
      room = build_room_with_players()

      updated_room = GameLogic.mark_player_ready(room, 999)

      assert updated_room == room
    end
  end

  describe "maybe_start_hand/1" do
    test "starts hand when room is waiting and all eligible players are ready" do
      room =
        build_room_with_players()
        |> Room.change(
          room_status: :waiting,
          players: %{
            1 =>
              Player.new(1, 1)
              |> Player.change(seat_position: 0, chips: 1000, ready?: true, busted?: false),
            2 =>
              Player.new(2, 2)
              |> Player.change(seat_position: 1, chips: 1000, ready?: true, busted?: false),
            3 =>
              Player.new(3, 3)
              |> Player.change(seat_position: 2, chips: 1000, ready?: true, busted?: false)
          }
        )

      updated_room = GameLogic.maybe_start_hand(room)

      assert updated_room.room_status == :playing
      assert updated_room.phase == :pre_flop
      assert updated_room.current_hand_number == 1
      assert updated_room.dealer_player_id == 2
      assert updated_room.current_player_turn == 3
    end

    test "does not start hand when not all eligible players are ready" do
      room =
        build_room_with_players()
        |> Room.change(
          room_status: :waiting,
          players: %{
            1 =>
              Player.new(1, 1)
              |> Player.change(seat_position: 0, chips: 1000, ready?: true, busted?: false),
            2 =>
              Player.new(2, 2)
              |> Player.change(seat_position: 1, chips: 1000, ready?: false, busted?: false),
            3 =>
              Player.new(3, 3)
              |> Player.change(seat_position: 2, chips: 1000, ready?: true, busted?: false)
          }
        )

      updated_room = GameLogic.maybe_start_hand(room)

      assert updated_room == room
    end

    test "ignores busted players when checking readiness" do
      room =
        build_room_with_players()
        |> Room.change(
          room_status: :waiting,
          players: %{
            1 =>
              Player.new(1, 1)
              |> Player.change(seat_position: 0, chips: 1000, ready?: true, busted?: false),
            2 =>
              Player.new(2, 2)
              |> Player.change(seat_position: 1, chips: 1000, ready?: true, busted?: false),
            3 =>
              Player.new(3, 3)
              |> Player.change(seat_position: 2, chips: 0, ready?: false, busted?: true)
          }
        )

      updated_room = GameLogic.maybe_start_hand(room)

      assert updated_room.room_status == :playing
      assert updated_room.phase == :pre_flop
      assert Map.has_key?(updated_room.players, 3) == false
    end

    test "does not start hand unless room status is waiting" do
      room =
        build_room_with_players()
        |> Room.change(
          room_status: :playing,
          players: %{
            1 =>
              Player.new(1, 1)
              |> Player.change(seat_position: 0, chips: 1000, ready?: true, busted?: false),
            2 =>
              Player.new(2, 2)
              |> Player.change(seat_position: 1, chips: 1000, ready?: true, busted?: false),
            3 =>
              Player.new(3, 3)
              |> Player.change(seat_position: 2, chips: 1000, ready?: true, busted?: false)
          }
        )

      updated_room = GameLogic.maybe_start_hand(room)

      assert updated_room == room
    end
  end

  describe "end_hand_by_fold/1" do
    test "awards pot to the last active player and resets room to waiting" do
      room =
        build_room_with_players()
        |> Room.change(
          pot: 180,
          room_status: :playing,
          players: %{
            1 =>
              Player.new(1, 1)
              |> Player.change(
                seat_position: 0,
                chips: 1000,
                folded?: false,
                ready?: true
              ),
            2 =>
              Player.new(2, 2)
              |> Player.change(
                seat_position: 1,
                chips: 1000,
                folded?: true,
                ready?: true
              ),
            3 =>
              Player.new(3, 3)
              |> Player.change(
                seat_position: 2,
                chips: 1000,
                folded?: true,
                ready?: true
              )
          }
        )

      updated_room = GameLogic.end_hand_by_fold(room)

      assert updated_room.room_status == :waiting
      assert updated_room.current_player_turn == nil
      assert updated_room.winning_player_id == 1
      assert updated_room.winning_hand == nil
      assert updated_room.players[1].chips == 1180
      assert updated_room.players[1].ready? == false
      assert updated_room.players[2].ready? == false
      assert updated_room.players[3].ready? == false
    end
  end
end
