defmodule GameSite.MultiPoker.HandEvaluatorTest do
  use ExUnit.Case, async: true

  alias GameSite.MultiPoker.{HandEvaluator, Player, Room}

  describe "score_hand/1" do
    test "scores a high card hand" do
      cards = [
        {14, :hearts},
        {11, :clubs},
        {9, :spades},
        {7, :diamonds},
        {4, :hearts},
        {3, :clubs},
        {2, :spades}
      ]

      assert HandEvaluator.score_hand(cards) == {1, [14, 11, 9, 7, 4]}
    end

    test "scores a pair hand" do
      cards = [
        {10, :hearts},
        {10, :clubs},
        {14, :spades},
        {9, :diamonds},
        {7, :hearts},
        {4, :clubs},
        {2, :spades}
      ]

      assert HandEvaluator.score_hand(cards) == {2, [10, 14, 9, 7]}
    end

    test "scores a two pair hand" do
      cards = [
        {13, :hearts},
        {13, :clubs},
        {9, :spades},
        {9, :diamonds},
        {14, :hearts},
        {4, :clubs},
        {2, :spades}
      ]

      assert HandEvaluator.score_hand(cards) == {3, [13, 9, 14]}
    end

    test "scores a three of a kind hand" do
      cards = [
        {8, :hearts},
        {8, :clubs},
        {8, :spades},
        {14, :diamonds},
        {11, :hearts},
        {4, :clubs},
        {2, :spades}
      ]

      assert HandEvaluator.score_hand(cards) == {4, [8, 14, 11]}
    end

    test "scores a straight hand" do
      cards = [
        {6, :hearts},
        {7, :clubs},
        {8, :spades},
        {9, :diamonds},
        {10, :hearts},
        {2, :clubs},
        {14, :spades}
      ]

      assert HandEvaluator.score_hand(cards) == {5, [10]}
    end

    test "scores an ace-low straight" do
      cards = [
        {14, :hearts},
        {2, :clubs},
        {3, :spades},
        {4, :diamonds},
        {5, :hearts},
        {9, :clubs},
        {11, :spades}
      ]

      assert HandEvaluator.score_hand(cards) == {5, [5]}
    end

    test "scores a flush hand" do
      cards = [
        {14, :hearts},
        {11, :hearts},
        {9, :hearts},
        {7, :hearts},
        {4, :hearts},
        {3, :clubs},
        {2, :spades}
      ]

      assert HandEvaluator.score_hand(cards) == {6, [14, 11, 9, 7, 4]}
    end

    test "scores a full house hand" do
      cards = [
        {12, :hearts},
        {12, :clubs},
        {12, :spades},
        {9, :diamonds},
        {9, :hearts},
        {4, :clubs},
        {2, :spades}
      ]

      assert HandEvaluator.score_hand(cards) == {7, [12, 9]}
    end

    test "scores a full house when there are two trips" do
      cards = [
        {13, :hearts},
        {13, :clubs},
        {13, :spades},
        {10, :diamonds},
        {10, :hearts},
        {10, :clubs},
        {2, :spades}
      ]

      assert HandEvaluator.score_hand(cards) == {7, [13, 10]}
    end

    test "scores a four of a kind hand" do
      cards = [
        {7, :hearts},
        {7, :clubs},
        {7, :spades},
        {7, :diamonds},
        {14, :hearts},
        {4, :clubs},
        {2, :spades}
      ]

      assert HandEvaluator.score_hand(cards) == {8, [7, 14]}
    end

    test "scores a straight flush hand" do
      cards = [
        {5, :hearts},
        {6, :hearts},
        {7, :hearts},
        {8, :hearts},
        {9, :hearts},
        {2, :clubs},
        {14, :spades}
      ]

      assert HandEvaluator.score_hand(cards) == {9, [9]}
    end

    test "scores a royal flush hand" do
      cards = [
        {10, :hearts},
        {11, :hearts},
        {12, :hearts},
        {13, :hearts},
        {14, :hearts},
        {2, :clubs},
        {7, :spades}
      ]

      assert HandEvaluator.score_hand(cards) == {10, [14]}
    end

    test "straight ignores duplicate values" do
      cards = [
        {6, :hearts},
        {7, :clubs},
        {8, :spades},
        {8, :diamonds},
        {9, :hearts},
        {10, :clubs},
        {2, :spades}
      ]

      assert HandEvaluator.score_hand(cards) == {5, [10]}
    end
  end

  describe "value helper functions" do
    test "returns nil for flush when not enough suited cards" do
      cards = [
        {14, :hearts},
        {11, :hearts},
        {9, :hearts},
        {7, :clubs},
        {4, :diamonds}
      ]

      assert HandEvaluator.flush_value(cards) == nil
    end

    test "returns nil for straight when no sequence exists" do
      cards = [
        {14, :hearts},
        {12, :clubs},
        {9, :spades},
        {7, :diamonds},
        {4, :hearts}
      ]

      assert HandEvaluator.straight_value(cards) == nil
    end

    test "returns nil for pair when no pair exists" do
      cards = [
        {14, :hearts},
        {12, :clubs},
        {9, :spades},
        {7, :diamonds},
        {4, :hearts}
      ]

      assert HandEvaluator.pair_value(cards) == nil
    end

    test "flush picks highest 5 cards when more than 5 suited cards exist" do
      cards = [
        {14, :hearts},
        {13, :hearts},
        {12, :hearts},
        {11, :hearts},
        {10, :hearts},
        {2, :hearts},
        {3, :clubs}
      ]

      assert HandEvaluator.flush_value(cards) == [14, 13, 12, 11, 10]
    end

    test "full house prefers highest trips and best pair" do
      cards = [
        {10, :hearts},
        {10, :clubs},
        {10, :spades},
        {9, :diamonds},
        {9, :hearts},
        {8, :clubs},
        {8, :spades}
      ]

      assert HandEvaluator.full_house_value(cards) == [10, 9]
    end

    test "royal_flush_value returns 14 for a royal flush" do
      cards = [
        {10, :hearts},
        {11, :hearts},
        {12, :hearts},
        {13, :hearts},
        {14, :hearts},
        {2, :clubs},
        {7, :spades}
      ]

      assert HandEvaluator.royal_flush_value(cards) == 14
    end

    test "straight_flush_value returns nil when there is no straight flush" do
      cards = [
        {10, :hearts},
        {11, :hearts},
        {13, :hearts},
        {14, :hearts},
        {2, :clubs},
        {7, :spades},
        {9, :hearts}
      ]

      assert HandEvaluator.straight_flush_value(cards) == nil
    end

    test "four_of_a_kind_value returns nil when there is no four of a kind" do
      cards = [
        {10, :hearts},
        {10, :clubs},
        {10, :spades},
        {14, :hearts},
        {9, :clubs},
        {7, :spades},
        {2, :diamonds}
      ]

      assert HandEvaluator.four_of_a_kind_value(cards) == nil
    end

    test "three_of_a_kind_value returns nil when there is no trips hand" do
      cards = [
        {10, :hearts},
        {10, :clubs},
        {14, :spades},
        {9, :hearts},
        {7, :clubs},
        {4, :spades},
        {2, :diamonds}
      ]

      assert HandEvaluator.three_of_a_kind_value(cards) == nil
    end

    test "two_pair_value returns nil when there are not two pairs" do
      cards = [
        {10, :hearts},
        {10, :clubs},
        {14, :spades},
        {9, :hearts},
        {7, :clubs},
        {4, :spades},
        {2, :diamonds}
      ]

      assert HandEvaluator.two_pair_value(cards) == nil
    end

    test "high_card_value returns the top five unique ranks in descending order" do
      cards = [
        {14, :hearts},
        {14, :clubs},
        {12, :spades},
        {9, :diamonds},
        {7, :hearts},
        {4, :clubs},
        {2, :spades}
      ]

      assert HandEvaluator.high_card_value(cards) == [14, 12, 9, 7, 4]
    end
  end

  describe "evaluate_hands/1" do
    test "orders players from best hand to worst hand" do
      room = %Room{
        community_cards: [
          {14, :hearts},
          {13, :clubs},
          {9, :spades},
          {4, :diamonds},
          {2, :hearts}
        ],
        players: %{
          1 => %Player{
            player_id: 1,
            hand: [{14, :clubs}, {10, :spades}]
          },
          2 => %Player{
            player_id: 2,
            hand: [{13, :hearts}, {13, :spades}]
          },
          3 => %Player{
            player_id: 3,
            hand: [{3, :clubs}, {5, :spades}]
          }
        }
      }

      ordered = HandEvaluator.evaluate_hands(room)

      assert [
               {3, _},
               {2, _},
               {1, _}
             ] = ordered
    end

    test "handles tied hands" do
      room = %Room{
        community_cards: [
          {14, :hearts},
          {13, :clubs},
          {9, :spades},
          {4, :diamonds},
          {2, :hearts}
        ],
        players: %{
          1 => %Player{
            player_id: 1,
            hand: [{10, :clubs}, {8, :spades}]
          },
          2 => %Player{
            player_id: 2,
            hand: [{10, :hearts}, {8, :clubs}]
          }
        }
      }

      result = HandEvaluator.evaluate_hands(room)

      assert length(result) == 2

      assert HandEvaluator.rank_hand(Enum.at(result, 0)) ==
               HandEvaluator.rank_hand(Enum.at(result, 1))
    end
  end

  describe "rank helpers" do
    test "get_rank returns the correct values" do
      assert HandEvaluator.get_rank(:high_card) == 1
      assert HandEvaluator.get_rank(:pair) == 2
      assert HandEvaluator.get_rank(:two_pair) == 3
      assert HandEvaluator.get_rank(:three_of_a_kind) == 4
      assert HandEvaluator.get_rank(:straight) == 5
      assert HandEvaluator.get_rank(:flush) == 6
      assert HandEvaluator.get_rank(:full_house) == 7
      assert HandEvaluator.get_rank(:four_of_a_kind) == 8
      assert HandEvaluator.get_rank(:straight_flush) == 9
      assert HandEvaluator.get_rank(:royal_flush) == 10
    end

    test "rank_hand delegates to score_hand" do
      cards = [
        {10, :hearts},
        {10, :clubs},
        {14, :spades},
        {9, :diamonds},
        {7, :hearts},
        {4, :clubs},
        {2, :spades}
      ]

      assert HandEvaluator.rank_hand({1, cards}) == HandEvaluator.score_hand(cards)
    end
  end

  describe "tie breakers" do
    test "higher pair beats lower pair" do
      pair_of_aces = [
        {14, :hearts},
        {14, :clubs},
        {11, :spades},
        {9, :diamonds},
        {7, :hearts},
        {4, :clubs},
        {2, :spades}
      ]

      pair_of_kings = [
        {13, :hearts},
        {13, :clubs},
        {14, :spades},
        {9, :diamonds},
        {7, :hearts},
        {4, :clubs},
        {2, :spades}
      ]

      assert HandEvaluator.score_hand(pair_of_aces) > HandEvaluator.score_hand(pair_of_kings)
    end

    test "higher two pair beats lower two pair" do
      aces_and_tens = [
        {14, :hearts},
        {14, :clubs},
        {10, :spades},
        {10, :diamonds},
        {7, :hearts},
        {4, :clubs},
        {2, :spades}
      ]

      kings_and_queens = [
        {13, :hearts},
        {13, :clubs},
        {12, :spades},
        {12, :diamonds},
        {14, :hearts},
        {4, :clubs},
        {2, :spades}
      ]

      assert HandEvaluator.score_hand(aces_and_tens) > HandEvaluator.score_hand(kings_and_queens)
    end

    test "higher straight beats lower straight" do
      ten_high = [
        {6, :hearts},
        {7, :clubs},
        {8, :spades},
        {9, :diamonds},
        {10, :hearts},
        {2, :clubs},
        {14, :spades}
      ]

      nine_high = [
        {5, :hearts},
        {6, :clubs},
        {7, :spades},
        {8, :diamonds},
        {9, :hearts},
        {2, :clubs},
        {14, :spades}
      ]

      assert HandEvaluator.score_hand(ten_high) > HandEvaluator.score_hand(nine_high)
    end

    test "higher flush beats lower flush" do
      ace_high_flush = [
        {14, :hearts},
        {12, :hearts},
        {10, :hearts},
        {7, :hearts},
        {3, :hearts},
        {2, :clubs},
        {9, :spades}
      ]

      king_high_flush = [
        {13, :hearts},
        {12, :hearts},
        {10, :hearts},
        {7, :hearts},
        {3, :hearts},
        {2, :clubs},
        {9, :spades}
      ]

      assert HandEvaluator.score_hand(ace_high_flush) > HandEvaluator.score_hand(king_high_flush)
    end

    test "higher full house beats lower full house" do
      aces_full = [
        {14, :hearts},
        {14, :clubs},
        {14, :spades},
        {13, :diamonds},
        {13, :hearts},
        {2, :clubs},
        {3, :spades}
      ]

      kings_full = [
        {13, :hearts},
        {13, :clubs},
        {13, :spades},
        {14, :diamonds},
        {14, :hearts},
        {2, :clubs},
        {3, :spades}
      ]

      assert HandEvaluator.score_hand(aces_full) > HandEvaluator.score_hand(kings_full)
    end
  end
end
