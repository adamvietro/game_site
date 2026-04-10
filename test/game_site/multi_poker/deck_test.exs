defmodule GameSite.MultiPoker.DeckTest do
  use ExUnit.Case, async: true

  alias GameSite.MultiPoker.Deck

  describe "create_deck/0" do
    test "creates a standard 52 card deck" do
      deck = Deck.create_deck()

      assert length(deck) == 52
      assert Enum.uniq(deck) == deck
    end

    test "includes every rank and suit combination" do
      deck = Deck.create_deck()

      assert {2, "spades"} in deck
      assert {2, "clubs"} in deck
      assert {2, "diamonds"} in deck
      assert {2, "hearts"} in deck

      assert {14, "spades"} in deck
      assert {14, "clubs"} in deck
      assert {14, "diamonds"} in deck
      assert {14, "hearts"} in deck
    end

    test "has the expected ordering" do
      deck = Deck.create_deck()

      assert Enum.take(deck, 4) == [
               {2, "spades"},
               {2, "clubs"},
               {2, "diamonds"},
               {2, "hearts"}
             ]

      assert Enum.take(deck, -4) == [
               {14, "spades"},
               {14, "clubs"},
               {14, "diamonds"},
               {14, "hearts"}
             ]
    end
  end

  describe "shuffle_cards/1" do
    test "returns a deck with the same cards" do
      deck = Deck.create_deck()
      shuffled = Deck.shuffle_cards(deck)

      assert length(shuffled) == 52
      assert Enum.sort(shuffled) == Enum.sort(deck)
    end
  end

  describe "choose_n_cards/2" do
    test "chooses n cards from the top of the deck" do
      deck = [
        {2, "spades"},
        {3, "clubs"},
        {4, "diamonds"},
        {5, "hearts"}
      ]

      [dealt_cards, remaining_deck] = Deck.choose_n_cards(deck, 2)

      assert dealt_cards == [
               {3, "clubs"},
               {2, "spades"}
             ]

      assert remaining_deck == [
               {4, "diamonds"},
               {5, "hearts"}
             ]
    end

    test "chooses all cards when n equals deck size" do
      deck = [
        {2, "spades"},
        {3, "clubs"}
      ]

      [dealt_cards, remaining_deck] = Deck.choose_n_cards(deck, 2)

      assert dealt_cards == [
               {3, "clubs"},
               {2, "spades"}
             ]

      assert remaining_deck == []
    end

    test "returns empty dealt cards when n is 0" do
      deck = Deck.create_deck()

      [dealt_cards, remaining_deck] = Deck.choose_n_cards(deck, 0)

      assert dealt_cards == []
      assert remaining_deck == deck
    end

    test "returns nil entries if more cards are requested than remain" do
      deck = [
        {2, "spades"}
      ]

      [dealt_cards, remaining_deck] = Deck.choose_n_cards(deck, 3)

      assert dealt_cards == [nil, nil, {2, "spades"}]
      assert remaining_deck == []
    end
  end
end
