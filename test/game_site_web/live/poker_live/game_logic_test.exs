defmodule GameSiteWeb.Live.PokerLive.GameLogicTest do
  use ExUnit.Case, async: true

  alias GameSiteWeb.Live.PokerLive.GameLogic

  describe "new_game/0" do
    test "returns the default game state" do
      game = GameLogic.new_game()

      assert game.hand == []
      assert game.cards == []
      assert game.state == "initial"
      assert game.wager == 10
      assert game.score == 100
      assert game.selected_cards == []
      assert game.all_in == false
    end
  end

  describe "modify_game/2" do
    test "updates only the given fields" do
      game = GameLogic.new_game()

      updated =
        GameLogic.modify_game(game, %{
          wager: 25,
          score: 80,
          all_in: true
        })

      assert updated.wager == 25
      assert updated.score == 80
      assert updated.all_in == true

      assert updated.state == "initial"
      assert updated.hand == []
      assert updated.cards == []
    end
  end

  describe "deal_cards/0" do
    test "returns a 5 card hand and remaining deck" do
      {hand, cards} = GameLogic.deal_cards()

      assert length(hand) == 5
      assert length(cards) == 47
      assert Enum.uniq(hand) == hand
    end
  end

  describe "advance_game/2 initial state" do
    test "deals a new hand and moves to dealt state" do
      game = GameLogic.new_game()

      updated = GameLogic.advance_game(game, nil)

      assert updated.state == "dealt"
      assert length(updated.hand) == 5
      assert length(updated.cards) == 47
    end
  end

  describe "advance_game/2 dealt state" do
    test "replaces selected cards and moves to final state" do
      game = %GameLogic{
        hand: [
          {2, "hearts"},
          {5, "clubs"},
          {9, "spades"},
          {11, "diamonds"},
          {14, "hearts"}
        ],
        cards: [
          {3, "clubs"},
          {4, "clubs"},
          {6, "clubs"},
          {7, "clubs"},
          {8, "clubs"}
        ],
        state: "dealt"
      }

      updated =
        GameLogic.advance_game(game, %{
          "replace" => ["2:hearts", "5:clubs"]
        })

      assert updated.state == "final"
      assert length(updated.hand) == 5
      assert length(updated.cards) == 3

      refute {2, "hearts"} in updated.hand
      refute {5, "clubs"} in updated.hand
      assert {3, "clubs"} in updated.hand
      assert {4, "clubs"} in updated.hand
    end

    test "with no selected cards keeps hand and moves to final state" do
      hand = [
        {2, "hearts"},
        {5, "clubs"},
        {9, "spades"},
        {11, "diamonds"},
        {14, "hearts"}
      ]

      game = %GameLogic{
        hand: hand,
        cards: [
          {3, "clubs"},
          {4, "clubs"}
        ],
        state: "dealt"
      }

      updated = GameLogic.advance_game(game, %{})

      assert updated.state == "final"
      assert updated.hand == hand
      assert length(updated.cards) == 2
    end
  end

  describe "advance_game/2 final state" do
    test "high card loses wager and moves to reset" do
      game = %GameLogic{
        hand: [
          {2, "hearts"},
          {5, "clubs"},
          {9, "spades"},
          {11, "diamonds"},
          {14, "hearts"}
        ],
        state: "final",
        score: 100,
        wager: 10,
        all_in: true
      }

      updated = GameLogic.advance_game(game, nil)

      assert updated.state == "reset"
      assert updated.score == 90
      assert updated.wager == 10
      assert updated.all_in == false
    end

    test "low one pair loses wager and moves to reset" do
      game = %GameLogic{
        hand: [
          {9, "hearts"},
          {9, "clubs"},
          {2, "spades"},
          {5, "diamonds"},
          {14, "hearts"}
        ],
        state: "final",
        score: 100,
        wager: 10,
        all_in: true
      }

      updated = GameLogic.advance_game(game, nil)

      assert updated.state == "reset"
      assert updated.score == 90
      assert updated.wager == 10
      assert updated.all_in == false
    end

    test "high one pair wins wager and moves to reset" do
      game = %GameLogic{
        hand: [
          {11, "hearts"},
          {11, "clubs"},
          {2, "spades"},
          {5, "diamonds"},
          {14, "hearts"}
        ],
        state: "final",
        score: 100,
        wager: 10,
        all_in: true
      }

      updated = GameLogic.advance_game(game, nil)

      assert updated.state == "reset"
      assert updated.score == 110
      assert updated.wager == 10
      assert updated.all_in == false
    end

    test "better than one pair wins wager and moves to reset" do
      game = %GameLogic{
        hand: [
          {3, "hearts"},
          {3, "clubs"},
          {3, "spades"},
          {5, "diamonds"},
          {14, "hearts"}
        ],
        state: "final",
        score: 100,
        wager: 10,
        all_in: true
      }

      updated = GameLogic.advance_game(game, nil)

      assert updated.state == "reset"
      assert updated.score == 110
      assert updated.wager == 10
      assert updated.all_in == false
    end

    test "losing hand lowers wager when score drops below wager" do
      game = %GameLogic{
        hand: [
          {2, "hearts"},
          {5, "clubs"},
          {9, "spades"},
          {11, "diamonds"},
          {14, "hearts"}
        ],
        state: "final",
        score: 5,
        wager: 10,
        all_in: true
      }

      updated = GameLogic.advance_game(game, nil)

      assert updated.state == "reset"
      assert updated.score == -5
      assert updated.wager == -5
      assert updated.all_in == false
    end
  end

  describe "advance_game/2 reset state" do
    test "moves back to initial state" do
      game = %GameLogic{
        state: "reset",
        all_in: true
      }

      updated = GameLogic.advance_game(game, nil)

      assert updated.state == "initial"
      assert updated.all_in == false
    end
  end
end
