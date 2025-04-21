defmodule GameSiteWeb.GuessingLiveTest do
  use GameSiteWeb.ConnCase

  import Phoenix.LiveViewTest
  # import Phoenix.LiveView
  import GameSite.GamesFixtures
  import GameSite.AccountsFixtures

  describe "Guessing" do
    setup do
      user = user_fixture()
      game = game_fixture(%{game_id: 1})

      socket = %Phoenix.LiveView.Socket{
        assigns: %{
          answer: to_string(1),
          score: 10,
          attempt: 1,
          highest_score: 0,
          wager: 1,
          flash: %{},
          __changed__: %{}
        }
      }

      %{user: user, game: game, socket: socket}
    end

    test "access route", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user)

      {:ok, _index_live, html} = live(conn, ~p"/1")

      assert html =~ "Guessing Game"
    end

    test "one bad guess", %{conn: conn, user: user, socket: socket} do
      _conn = log_in_user(conn, user)

      {:noreply, updated_socket} =
        GameSiteWeb.GuessingLive.handle_event("answer", %{"guess" => "2", "wager" => "2"}, socket)

      assert updated_socket.assigns.attempt == 2
      assert updated_socket.assigns.wager == 2
      assert updated_socket.assigns.score == 10
      assert Phoenix.Flash.get(updated_socket.assigns.flash, :info) == "Incorrect."
    end

    test "5 bad guesses", %{conn: conn, user: user, socket: socket} do
      _conn = log_in_user(conn, user)

      socket =
        Enum.reduce(1..5, socket, fn _n, acc_socket ->
          {:noreply, new_socket} =
            GameSiteWeb.GuessingLive.handle_event(
              "answer",
              %{"guess" => "2", "wager" => "2"},
              acc_socket
            )

          new_socket
        end)

      assert socket.assigns.attempt == 1
      assert socket.assigns.wager == 2
      assert socket.assigns.score == 8
      assert Phoenix.Flash.get(socket.assigns.flash, :info) == "Out of Guesses."
    end
  end
end
