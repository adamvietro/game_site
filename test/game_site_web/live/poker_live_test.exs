defmodule GameSiteWeb.PokerLiveTest do
  alias GameSiteWeb.PokerLive
  use GameSiteWeb.ConnCase

  import Phoenix.LiveViewTest
  import GameSite.GamesFixtures
  import GameSite.AccountsFixtures
  import GameSiteWeb.PokerLive

  describe "helper functions" do
    test "cards/0" do
      cards = PokerLive.cards()

      assert length(cards) == 52
    end

    test "shuffle/1" do
      cards = PokerLive.cards()
      shuffled = PokerLive.shuffle(cards)

      assert length(cards) == length(shuffled)
      assert cards != shuffled
    end

    test "choose_5/1" do
      cards = PokerLive.cards()
      shuffled = PokerLive.shuffle(cards)
      {hand, cards} = PokerLive.choose_5(shuffled)

      assert length(hand) == 5
      assert length(cards) == 47
    end

    test "remove_cards/2" do
      cards = PokerLive.cards()
      shuffled = PokerLive.shuffle(cards)
      {hand, _cards} = PokerLive.choose_5(shuffled)

      [hand, selected_cards] = select_n_cards(hand, 3)
      hand = PokerLive.remove_cards(selected_cards, hand)

      assert length(hand) == 2
      assert length(selected_cards) == 3
    end

    test "choose/3" do
      cards = PokerLive.cards()
      shuffled = PokerLive.shuffle(cards)
      {hand, cards} = PokerLive.choose_5(shuffled)

      [hand, selected_cards] = select_n_cards(hand, 3)
      hand = PokerLive.remove_cards(selected_cards, hand)
      [hand, cards] = PokerLive.choose(cards, hand, 3)

      assert length(hand) == 5
      assert length(cards) == 44
    end
  end

  describe "classify/1" do
    test "royal_flush" do
      hand = [
        {14, "spades"},
        {13, "spades"},
        {12, "spades"},
        {11, "spades"},
        {10, "spades"}
      ]

      assert {:royal_flush, "spades"} = PokerLive.classify(hand)
    end

    test "straight_flush" do
      hand = [
        {9, "spades"},
        {13, "spades"},
        {12, "spades"},
        {11, "spades"},
        {10, "spades"}
      ]

      assert {:straight_flush, 13} = PokerLive.classify(hand)
    end

    test "four_of_a_kind" do
      hand = [
        {9, "spades"},
        {9, "clubs"},
        {9, "spades"},
        {9, "spades"},
        {10, "spades"}
      ]

      assert {:four_of_a_kind, %{9 => 4}} = PokerLive.classify(hand)
    end

    assert "full_house" do
      hand = [
        {9, "spades"},
        {9, "clubs"},
        {10, "spades"},
        {10, "spades"},
        {10, "spades"}
      ]

      assert {:full_house, %{10 => 3}} = PokerLive.classify(hand)
    end

    test "flush" do
      hand = [
        {9, "spades"},
        {7, "spades"},
        {10, "spades"},
        {11, "spades"},
        {6, "spades"}
      ]

      assert {:flush, "spades"} = PokerLive.classify(hand)
    end

    test "is_straight" do
      hand = [
        {9, "spades"},
        {7, "spades"},
        {10, "clubs"},
        {11, "spades"},
        {8, "spades"}
      ]

      assert {:straight, 11} = PokerLive.classify(hand)
    end

    test "three_of_a_kind" do
      hand = [
        {9, "spades"},
        {9, "spades"},
        {9, "clubs"},
        {11, "spades"},
        {6, "spades"}
      ]

      assert {:three_of_a_kind, %{9 => 3}} = PokerLive.classify(hand)
    end

    test "two_pair" do
      hand = [
        {9, "spades"},
        {9, "spades"},
        {10, "clubs"},
        {10, "spades"},
        {6, "spades"}
      ]

      assert {:two_pair, %{10 => 2, 9 => 2}} = PokerLive.classify(hand)
    end

    test "one_pair" do
      hand = [
        {9, "spades"},
        {9, "spades"},
        {13, "clubs"},
        {5, "spades"},
        {6, "spades"}
      ]

      assert {:one_pair, %{9 => 2}} = PokerLive.classify(hand)
    end

    test "high_card" do
      hand = [
        {9, "spades"},
        {4, "spades"},
        {13, "clubs"},
        {5, "spades"},
        {6, "spades"}
      ]

      assert {:high_card, 13} = PokerLive.classify(hand)
    end
  end

  def select_n_cards(hand, number) do
    Enum.reduce(0..(number - 1), [hand, []], fn _, [hand, selected] ->
      {card, hand} = List.pop_at(hand, 0)
      [hand, [card | selected]]
    end)
  end
end
