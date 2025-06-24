defmodule GameSiteWeb.PokerHelpersTest do
  use GameSiteWeb.ConnCase

  import Phoenix.LiveViewTest
  # import GameSite.GamesFixtures
  import GameSite.AccountsFixtures
  alias GameSiteWeb.PokerHelpers

  describe "helper functions" do
    test "cards/0" do
      cards = PokerHelpers.cards()

      assert length(cards) == 52
    end

    test "shuffle/1" do
      cards = PokerHelpers.cards()
      shuffled = PokerHelpers.shuffle(cards)

      assert length(cards) == length(shuffled)
      assert cards != shuffled
    end

    test "choose_5/1" do
      cards = PokerHelpers.cards()
      shuffled = PokerHelpers.shuffle(cards)
      {hand, cards} = PokerHelpers.choose_5(shuffled)

      assert length(hand) == 5
      assert length(cards) == 47
    end

    test "remove_cards/2" do
      cards = PokerHelpers.cards()
      shuffled = PokerHelpers.shuffle(cards)
      {hand, _cards} = PokerHelpers.choose_5(shuffled)

      [hand, selected_cards] = select_n_cards(hand, 3)
      hand = PokerHelpers.remove_cards(selected_cards, hand)

      assert length(hand) == 2
      assert length(selected_cards) == 3
    end

    test "choose/3" do
      cards = PokerHelpers.cards()
      shuffled = PokerHelpers.shuffle(cards)
      {hand, cards} = PokerHelpers.choose_5(shuffled)

      [hand, selected_cards] = select_n_cards(hand, 3)
      hand = PokerHelpers.remove_cards(selected_cards, hand)
      [hand, cards] = PokerHelpers.choose(cards, hand, 3)

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

      assert {:royal_flush, "spades"} = PokerHelpers.classify(hand)
    end

    test "straight_flush" do
      hand = [
        {9, "spades"},
        {13, "spades"},
        {12, "spades"},
        {11, "spades"},
        {10, "spades"}
      ]

      assert {:straight_flush, 13} = PokerHelpers.classify(hand)
    end

    test "four_of_a_kind" do
      hand = [
        {9, "spades"},
        {9, "clubs"},
        {9, "spades"},
        {9, "spades"},
        {10, "spades"}
      ]

      assert {:four_of_a_kind, %{9 => 4}} = PokerHelpers.classify(hand)
    end

    assert "full_house" do
      hand = [
        {9, "spades"},
        {9, "clubs"},
        {10, "spades"},
        {10, "spades"},
        {10, "spades"}
      ]

      assert {:full_house, %{10 => 3}} = PokerHelpers.classify(hand)
    end

    test "flush" do
      hand = [
        {9, "spades"},
        {7, "spades"},
        {10, "spades"},
        {11, "spades"},
        {6, "spades"}
      ]

      assert {:flush, "spades"} = PokerHelpers.classify(hand)
    end

    test "is_straight" do
      hand = [
        {9, "spades"},
        {7, "spades"},
        {10, "clubs"},
        {11, "spades"},
        {8, "spades"}
      ]

      assert {:straight, 11} = PokerHelpers.classify(hand)
    end

    test "three_of_a_kind" do
      hand = [
        {9, "spades"},
        {9, "spades"},
        {9, "clubs"},
        {11, "spades"},
        {6, "spades"}
      ]

      assert {:three_of_a_kind, %{9 => 3}} = PokerHelpers.classify(hand)
    end

    test "two_pair" do
      hand = [
        {9, "spades"},
        {9, "spades"},
        {10, "clubs"},
        {10, "spades"},
        {6, "spades"}
      ]

      assert {:two_pair, %{10 => 2, 9 => 2}} = PokerHelpers.classify(hand)
    end

    test "one_pair" do
      hand = [
        {9, "spades"},
        {9, "spades"},
        {13, "clubs"},
        {5, "spades"},
        {6, "spades"}
      ]

      assert {:one_pair, %{9 => 2}} = PokerHelpers.classify(hand)
    end

    test "high_card" do
      hand = [
        {9, "spades"},
        {4, "spades"},
        {13, "clubs"},
        {5, "spades"},
        {6, "spades"}
      ]

      assert {:high_card, 13} = PokerHelpers.classify(hand)
    end
  end

  describe "events" do
    setup do
      user = user_fixture()
      # game = game_fixture(%{game_id: 5})

      %{user: user}
    end

    test "new", %{conn: conn, user: user} do
      [_conn, socket] = log_in_and_socket(conn, user)

      {:noreply, new_socket} =
        GameSiteWeb.PokerLive.handle_event(
          "new",
          nil,
          socket
        )

      assert new_socket.assigns.score == 100
      assert new_socket.assigns.highest_score == 100
      assert length(new_socket.assigns.cards) == 47
      assert length(new_socket.assigns.hand) == 5
    end

    test "redraw", %{conn: conn, user: user} do
      [_conn, socket] = log_in_and_socket(conn, user)

      {:noreply, socket} =
        GameSiteWeb.PokerLive.handle_event(
          "new",
          nil,
          socket
        )

      assert length(socket.assigns.cards) == 47
      assert length(socket.assigns.hand) == 5

      [_hand, cards_to_remove] = select_n_cards(socket.assigns.hand, 3)


      {:noreply, socket} =
        GameSiteWeb.PokerLive.handle_event(
          "redraw",
          %{"replace" => cards_to_remove},
          socket
        )

      assert length(socket.assigns.cards) == 44
      assert length(socket.assigns.hand) == 5
    end
  end

  defp select_n_cards(hand, number) do
    Enum.reduce(0..(number - 1), [hand, []], fn _, [hand, selected] ->
      {{rank, suit}, hand} = List.pop_at(hand, 0)

      [hand, ["#{rank}:#{suit}" | selected]]
    end)
  end

  defp log_in_and_socket(conn, user) do
    conn =
      conn
      |> log_in_user(user)

    {:ok, view, _html} = live(conn, ~p"/5")

    state = :sys.get_state(view.pid)
    socket = state.socket

    [conn, socket]
  end
end
