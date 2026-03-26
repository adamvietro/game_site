defmodule GameSiteWeb.PokerLiveTest do
  use GameSiteWeb.ConnCase

  import Phoenix.LiveViewTest
  import GameSite.AccountsFixtures

  defp get_socket(view) do
    state = :sys.get_state(view.pid)
    state.socket
  end

  defp log_in_and_socket(conn, user) do
    conn = log_in_user(conn, user)
    {:ok, view, _html} = live(conn, ~p"/poker")
    socket = get_socket(view)

    %{conn: conn, view: view, socket: socket}
  end

  describe "events" do
    setup %{conn: conn} do
      user = user_fixture()

      %{conn: conn, view: view, socket: socket} = log_in_and_socket(conn, user)

      %{
        conn: conn,
        view: view,
        socket: socket,
        user: user
      }
    end

    test "new", %{socket: socket} do
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

    test "deal", %{socket: socket} do
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
end
