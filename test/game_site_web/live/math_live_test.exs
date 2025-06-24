defmodule GameSiteWeb.MathLiveTest do
  use GameSiteWeb.ConnCase

  import Phoenix.LiveViewTest
  import GameSite.GamesFixtures
  import GameSite.AccountsFixtures

  defp log_in_and_socket(conn, user) do
    conn =
      conn
      |> log_in_user(user)

    {:ok, view, _html} = live(conn, ~p"/2")

    state = :sys.get_state(view.pid)
    socket = state.socket

    [conn, socket]
  end

  describe "Math" do
    setup do
      user = user_fixture()
      game = game_fixture(%{game_id: 2})

      %{user: user, game: game}
    end

    test "access route", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user)

      {:ok, _view, html} = live(conn, ~p"/2")

      assert html =~ "Math Game"
    end

    test "good guess bad wager", %{conn: conn, user: user} do
      [_conn, socket] = log_in_and_socket(conn, user)
      answer = socket.assigns.answer

      {:noreply, new_socket} =
        GameSiteWeb.MathLive.handle_event(
          "answer",
          %{"guess" => to_string(answer), "wager" => ""},
          socket
        )

      assert new_socket.assigns.score == 11
      assert new_socket.assigns.wager == 1
      assert Phoenix.Flash.get(new_socket.assigns.flash, :info) == "Correct!"
    end

    test "bad guess", %{conn: conn, user: user} do
      [_conn, socket] = log_in_and_socket(conn, user)
      answer = socket.assigns.answer

      {:noreply, new_socket} =
        GameSiteWeb.MathLive.handle_event(
          "answer",
          %{"guess" => to_string(String.to_integer(answer) + 1), "wager" => "5"},
          socket
        )

      assert new_socket.assigns.score == 5
      assert new_socket.assigns.wager == 5
      assert new_socket.assigns.highest_score == 5
      assert Phoenix.Flash.get(new_socket.assigns.flash, :error) == "Incorrect"
    end

    test "bad guess score less than wager", %{conn: conn, user: user} do
      [_conn, socket] = log_in_and_socket(conn, user)
      answer = socket.assigns.answer

      {:noreply, new_socket} =
        GameSiteWeb.MathLive.handle_event(
          "answer",
          %{"guess" => to_string(String.to_integer(answer) + 1), "wager" => "6"},
          socket
        )

      assert new_socket.assigns.score == 4
      assert new_socket.assigns.wager == 4
      assert new_socket.assigns.highest_score == 4
      assert Phoenix.Flash.get(new_socket.assigns.flash, :error) == "Incorrect"
    end

    test "exit after a correct answer", %{conn: conn, user: user, game: game} do
      [_conn, socket] = log_in_and_socket(conn, user)
      answer = socket.assigns.answer

      {:noreply, updated_socket} =
        GameSiteWeb.MathLive.handle_event(
          "answer",
          %{"guess" => to_string(answer), "wager" => "10"},
          socket
        )

      assert updated_socket.assigns.score == 20
      assert updated_socket.assigns.wager == 10
      assert updated_socket.assigns.highest_score == 20

      {:noreply, updated_socket} =
        GameSiteWeb.MathLive.handle_event(
          "exit",
          %{
            "user_id" => user.id,
            "score" => updated_socket.assigns.highest_score,
            "game_id" => game.id
          },
          updated_socket
        )

            assert Phoenix.Flash.get(updated_socket.assigns.flash, :info) ==
               "Score created successfully"
    end
  end
end
