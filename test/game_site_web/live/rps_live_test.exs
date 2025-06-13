defmodule GameSite.RPSTest do
  use GameSiteWeb.ConnCase

  import Phoenix.LiveViewTest
  import GameSite.GamesFixtures
  import GameSite.AccountsFixtures

  defp log_in_and_socket(conn, user) do
    conn =
      conn
      |> log_in_user(user)

    {:ok, view, _html} = live(conn, ~p"/3")

    state = :sys.get_state(view.pid)
    socket = state.socket

    [conn, socket]
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

  describe "Rock Paper Scissors" do
    setup do
      user = user_fixture()
      game = game_fixture(%{game_id: 3})

      %{user: user, game: game}
    end

    test "access route", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user)

      {:ok, _view, html} = live(conn, ~p"/3")

      assert html =~ "Rock Paper"
    end

    test "good guess", %{conn: conn, user: user} do
      [_conn, socket] = log_in_and_socket(conn, user)
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
      assert new_socket.assigns.outcome == "You Win!"
    end

    test "good guess bad wager", %{conn: conn, user: user} do
      [_conn, socket] = log_in_and_socket(conn, user)
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
      assert new_socket.assigns.outcome == "You Win!"
    end

    test "bad guess", %{conn: conn, user: user} do
      [_conn, socket] = log_in_and_socket(conn, user)
      computer = socket.assigns.computer
      lose = get_loser(computer)

      {:noreply, new_socket} =
        GameSiteWeb.RockPaperScissorsLive.handle_event(
          "answer",
          %{"player_choice" => lose, "wager" => "5"},
          socket
        )

      assert new_socket.assigns.score == 5
      assert new_socket.assigns.highest_score == 0
      assert new_socket.assigns.outcome == "You Lose!"
    end

    test "bad guess and score less than wager", %{conn: conn, user: user} do
      [_conn, socket] = log_in_and_socket(conn, user)
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
      assert new_socket.assigns.highest_score == 0
      assert new_socket.assigns.outcome == "You Lose!"
    end

    test "tie", %{conn: conn, user: user} do
      [_conn, socket] = log_in_and_socket(conn, user)
      computer = socket.assigns.computer

      {:noreply, new_socket} =
        GameSiteWeb.RockPaperScissorsLive.handle_event(
          "answer",
          %{"player_choice" => computer, "wager" => "6"},
          socket
        )

      assert new_socket.assigns.score == 10
      assert new_socket.assigns.wager == 6
      assert new_socket.assigns.highest_score == 0
      assert new_socket.assigns.outcome == "You Tie!"
    end

    test "wrong answer and reset after score goes to 0", %{conn: conn, user: user} do
      [_conn, socket] = log_in_and_socket(conn, user)
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
      assert new_socket.assigns.outcome == ""
      assert Phoenix.Flash.get(new_socket.assigns.flash, :error) == "Score at 0, resetting."
    end

    test "exit after a correct answer", %{conn: conn, user: user, game: game} do
      [_conn, socket] = log_in_and_socket(conn, user)
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
      assert new_socket.assigns.outcome == "You Win!"

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
end
