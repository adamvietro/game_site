defmodule GameSiteWeb.GuessingLiveTest do
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
    {:ok, view, _html} = live(conn, ~p"/guessing")
    socket = get_socket(view)

    %{conn: conn, view: view, socket: socket}
  end

  defp run_five_times(socket, wager) do
    Enum.reduce(1..5, socket, fn _n, acc_socket ->
      {:noreply, new_socket} =
        GameSiteWeb.GuessingLive.handle_event(
          "answer",
          %{"guess" => "11", "wager" => wager},
          acc_socket
        )

      new_socket
    end)
  end

  describe "Guessing" do
    setup %{conn: conn} do
      user = user_fixture()
      game = game_fixture(%{game_id: 1})

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
      assert render(view) =~ "Attempt"
    end

    test "good guess", %{socket: socket} do
      answer = socket.assigns.game.answer

      {:noreply, new_socket} =
        GameSiteWeb.GuessingLive.handle_event(
          "answer",
          %{"guess" => to_string(answer), "wager" => "2"},
          socket
        )

      assert new_socket.assigns.game.attempt == 1
      assert new_socket.assigns.game.wager == 2
      assert new_socket.assigns.game.score == 12
    end

    test "good guess, no wager", %{socket: socket} do
      answer = socket.assigns.game.answer

      {:noreply, new_socket} =
        GameSiteWeb.GuessingLive.handle_event(
          "answer",
          %{"guess" => to_string(answer), "wager" => "2"},
          socket
        )

      assert new_socket.assigns.game.attempt == 1
      assert new_socket.assigns.game.wager == 2
      assert new_socket.assigns.game.score == 12
    end

    test "one bad guess", %{socket: socket} do
      {:noreply, updated_socket} =
        GameSiteWeb.GuessingLive.handle_event(
          "answer",
          %{"guess" => "11", "wager" => "2"},
          socket
        )

      assert updated_socket.assigns.game.attempt == 2
      assert updated_socket.assigns.game.wager == 2
      assert updated_socket.assigns.game.score == 10
    end

    test "5 bad guesses", %{socket: socket} do
      socket = run_five_times(socket, "2")

      assert socket.assigns.game.attempt == 1
      assert socket.assigns.game.wager == 2
      assert socket.assigns.game.score == 8
    end

    test "reset on 5 bad guesses and full wager", %{socket: socket} do
      socket = run_five_times(socket, "10")

      assert socket.assigns.game.attempt == 1
      assert socket.assigns.game.score == 10
      assert socket.assigns.game.wager == 1
    end

    test "wager is set to the min of wager and score", %{socket: socket} do
      socket = run_five_times(socket, "6")

      assert socket.assigns.game.wager == 4
      assert socket.assigns.game.score == 4
    end

    test "exit after a correct answer", %{socket: socket, user: user, game: game} do
      answer = socket.assigns.game.answer

      {:noreply, updated_socket} =
        GameSiteWeb.GuessingLive.handle_event(
          "answer",
          %{"guess" => to_string(answer), "wager" => "2"},
          socket
        )

      assert updated_socket.assigns.game.score == 12
      assert updated_socket.assigns.game.wager == 2
      assert updated_socket.assigns.game.attempt == 1

      {:noreply, updated_socket} =
        GameSiteWeb.GuessingLive.handle_event(
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
