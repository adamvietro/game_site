defmodule GameSiteWeb.MathLiveTest do
  use GameSiteWeb.ConnCase

  import Phoenix.LiveViewTest
  import GameSite.GamesFixtures
  import GameSite.AccountsFixtures

  defp get_socket(view) do
    state = :sys.get_state(view.pid)
    state.socket
  end

  defp log_in_and_socket(conn, user) do
    conn = log_in_user(conn, user)
    {:ok, view, _html} = live(conn, ~p"/math")
    socket = get_socket(view)

    %{conn: conn, view: view, socket: socket}
  end

  describe "Math" do
    setup %{conn: conn} do
      user = user_fixture()
      game = game_fixture(%{game_id: 2})

      %{conn: conn, view: view, socket: socket} = log_in_and_socket(conn, user)

      %{
        conn: conn,
        view: view,
        socket: socket,
        user: user,
        game: game
      }
    end

    test "access route", %{view: view} do
      assert render(view) =~ "Question"
    end

    test "good guess bad wager", %{socket: socket} do
      answer = socket.assigns.game.answer

      {:noreply, new_socket} =
        GameSiteWeb.MathLive.handle_event(
          "answer",
          %{"guess" => to_string(answer), "wager" => ""},
          socket
        )

      assert new_socket.assigns.game.score == 11
      assert new_socket.assigns.game.wager == 1
    end

    test "bad guess", %{socket: socket} do
      answer = socket.assigns.game.answer

      {:noreply, new_socket} =
        GameSiteWeb.MathLive.handle_event(
          "answer",
          %{"guess" => to_string(String.to_integer(answer) + 1), "wager" => "5"},
          socket
        )

      assert new_socket.assigns.game.score == 5
      assert new_socket.assigns.game.wager == 5
      assert new_socket.assigns.game.highest_score == 5
    end

    test "bad guess score less than wager", %{socket: socket} do
      answer = socket.assigns.game.answer

      {:noreply, new_socket} =
        GameSiteWeb.MathLive.handle_event(
          "answer",
          %{"guess" => to_string(String.to_integer(answer) + 1), "wager" => "6"},
          socket
        )

      assert new_socket.assigns.game.score == 4
      assert new_socket.assigns.game.wager == 4
      assert new_socket.assigns.game.highest_score == 4
    end

    test "exit after a correct answer", %{socket: socket, user: user, game: game} do
      answer = socket.assigns.game.answer

      {:noreply, updated_socket} =
        GameSiteWeb.MathLive.handle_event(
          "answer",
          %{"guess" => to_string(answer), "wager" => "10"},
          socket
        )

      assert updated_socket.assigns.game.score == 20
      assert updated_socket.assigns.game.wager == 10
      assert updated_socket.assigns.game.highest_score == 20

      {:noreply, updated_socket} =
        GameSiteWeb.MathLive.handle_event(
          "exit",
          %{
            "user_id" => user.id,
            "score" => updated_socket.assigns.game.highest_score,
            "game_id" => game.id
          },
          updated_socket
        )

      assert Phoenix.Flash.get(updated_socket.assigns.flash, :info) ==
               "Score created successfully"
    end
  end
end
