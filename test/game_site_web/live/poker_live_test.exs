defmodule GameSiteWeb.PokerLiveTest do
  use GameSiteWeb.ConnCase

  import Phoenix.LiveViewTest
  import GameSite.AccountsFixtures

  describe "events" do
    setup do
      user = user_fixture()

      %{user: user}
    end

    test "new", %{conn: conn, user: user} do
      [_conn, socket] = log_in_and_socket(conn, user)

      {:noreply, new_socket} =
        GameSiteWeb.PokerLive.handle_event(
          "new-hand",
          nil,
          socket
        )

      assert new_socket.assigns.game.score == 100
      assert new_socket.assigns.highest_score == 0
      assert length(new_socket.assigns.game.cards) == 0
      assert length(new_socket.assigns.game.hand) == 0
    end

    test "redraw", %{conn: conn, user: user} do
      [_conn, socket] = log_in_and_socket(conn, user)

      {:noreply, socket} =
        GameSiteWeb.PokerLive.handle_event(
          "new-hand",
          nil,
          socket
        )

      assert length(socket.assigns.game.cards) == 0
      assert length(socket.assigns.game.hand) == 0

      {:noreply, socket} =
        GameSiteWeb.PokerLive.handle_event(
          "advance",
          nil,
          socket
        )

      [_hand, cards_to_remove] = select_n_cards(socket.assigns.game.hand, 3)

      {:noreply, socket} =
        GameSiteWeb.PokerLive.handle_event(
          "advance",
          %{"replace" => cards_to_remove},
          socket
        )

      assert length(socket.assigns.game.cards) == 44
      assert length(socket.assigns.game.hand) == 5
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

    {:ok, view, _html} = live(conn, ~p"/poker")

    state = :sys.get_state(view.pid)
    socket = state.socket

    [conn, socket]
  end
end
