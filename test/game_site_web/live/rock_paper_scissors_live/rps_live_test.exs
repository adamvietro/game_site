defmodule GameSite.RPSTest do
  use GameSiteWeb.ConnCase

  import Phoenix.LiveViewTest
  import GameSite.GamesFixtures
  import GameSite.AccountsFixtures

  defp log_in_and_socket(conn, user) do
    conn =
      conn
      |> log_in_user(user)

    {:ok, view, _html} = live(conn, ~p"/rock-paper-scissors")

    state = :sys.get_state(view.pid)
    socket = state.socket

    [conn, socket]
  end

  describe "Rock Paper Scissors" do
    setup %{conn: conn} do
      user = user_fixture()
      game = game_fixture(%{game_id: 3})

      [conn, socket] = log_in_and_socket(conn, user)

      {:ok, conn: conn, socket: socket, user: user, game: game}
    end

    test "access route", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/rock-paper-scissors")

      assert html =~ "Rock Paper"
    end

    test "good guess", %{socket: socket} do
      computer = socket.assigns.computer
      winner = get_winner(computer)

      {:noreply, new_socket} =
        GameSiteWeb.RockPaperScissorsLive.handle_event(
          "answer",
          %{"player_choice" => winner, "wager" => "10"},
          socket
        )

      assert new_socket.assigns.score == 20
      assert new_socket.assigns.highest_score == 20
      assert new_socket.assigns.message == "You Win!!"
    end

    test "good guess bad wager", %{socket: socket} do
      computer = socket.assigns.computer
      winner = get_winner(computer)

      {:noreply, new_socket} =
        GameSiteWeb.RockPaperScissorsLive.handle_event(
          "answer",
          %{"player_choice" => winner, "wager" => ""},
          socket
        )

      assert new_socket.assigns.score == 11
      assert new_socket.assigns.highest_score == 11
      assert new_socket.assigns.message == "You Win!!"
    end

    test "bad guess", %{socket: socket} do
      computer = socket.assigns.computer
      lose = get_loser(computer)

      {:noreply, new_socket} =
        GameSiteWeb.RockPaperScissorsLive.handle_event(
          "answer",
          %{"player_choice" => lose, "wager" => "5"},
          socket
        )

      assert new_socket.assigns.score == 5
      assert new_socket.assigns.highest_score == 5
      assert new_socket.assigns.message == "You Lose!!"
    end

    test "bad guess higher wager", %{socket: socket} do
      computer = socket.assigns.computer
      lose = get_loser(computer)

      {:noreply, new_socket} =
        GameSiteWeb.RockPaperScissorsLive.handle_event(
          "answer",
          %{"player_choice" => lose, "wager" => "6"},
          socket
        )

      assert new_socket.assigns.score == 4
      assert new_socket.assigns.wager == 4
      assert new_socket.assigns.highest_score == 4
      assert new_socket.assigns.message == "You Lose!!"
    end

    test "tie", %{socket: socket} do
      computer = socket.assigns.computer

      {:noreply, new_socket} =
        GameSiteWeb.RockPaperScissorsLive.handle_event(
          "answer",
          %{"player_choice" => computer, "wager" => "6"},
          socket
        )

      assert new_socket.assigns.score == 10
      assert new_socket.assigns.wager == 6
      assert new_socket.assigns.highest_score == 10
      assert new_socket.assigns.message == "You Tie!!"
    end

    test "wrong answer and reset after score goes to 0", %{socket: socket} do
      computer = socket.assigns.computer
      lose = get_loser(computer)

      {:noreply, new_socket} =
        GameSiteWeb.RockPaperScissorsLive.handle_event(
          "answer",
          %{"player_choice" => lose, "wager" => "10"},
          socket
        )

      assert new_socket.assigns.score == 10
      assert new_socket.assigns.wager == 1
      assert new_socket.assigns.highest_score == 0
      assert new_socket.assigns.message == ""
      assert Phoenix.Flash.get(new_socket.assigns.flash, :error) == "Score at 0, resetting."
    end

    test "exit after a correct answer", %{socket: socket, user: user, game: game} do
      computer = socket.assigns.computer
      winner = get_winner(computer)

      {:noreply, new_socket} =
        GameSiteWeb.RockPaperScissorsLive.handle_event(
          "answer",
          %{"player_choice" => winner, "wager" => "10"},
          socket
        )

      assert new_socket.assigns.score == 20
      assert new_socket.assigns.highest_score == 20
      assert new_socket.assigns.outcome == nil
      assert new_socket.assigns.message == "You Win!!"

      {:noreply, updated_socket} =
        GameSiteWeb.RockPaperScissorsLive.handle_event(
          "exit",
          %{
            "user_id" => user.id,
            "score" => new_socket.assigns.highest_score,
            "game_id" => game.id
          },
          new_socket
        )

      assert Phoenix.Flash.get(updated_socket.assigns.flash, :info) ==
               "Score created successfully"
    end
  end

  defp get_winner(computer) do
    case computer do
      "rock" -> "paper"
      "paper" -> "scissor"
      "scissor" -> "rock"
    end
  end

  defp get_loser(computer) do
    case computer do
      "rock" -> "scissor"
      "scissor" -> "paper"
      "paper" -> "rock"
    end
  end
end
