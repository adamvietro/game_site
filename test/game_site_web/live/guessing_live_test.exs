defmodule GameSiteWeb.GuessingLiveTest do
  use GameSiteWeb.ConnCase

  import Phoenix.LiveViewTest
  import GameSite.GamesFixtures
  import GameSite.AccountsFixtures

  describe "Guessing" do
    setup do
      user = user_fixture()
      game = game_fixture(%{game_id: 1})

      %{user: user, game: game}
    end

    defp get_socket(view) do
      state = :sys.get_state(view.pid)
      state.socket
    end

    def run_five_times(socket, wager) do
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

    test "access route", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user)

      {:ok, _view, html} = live(conn, ~p"/1")

      assert html =~ "Guessing Game"
    end

    test "good guess", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user)

      {:ok, view, _html} = live(conn, ~p"/1")

      socket = get_socket(view)
      answer = socket.assigns.answer

      {:noreply, new_socket} =
        GameSiteWeb.GuessingLive.handle_event(
          "answer",
          %{"guess" => to_string(answer), "wager" => "2"},
          socket
        )

      assert new_socket.assigns.attempt == 1
      assert new_socket.assigns.wager == 2
      assert new_socket.assigns.score == 12
      assert Phoenix.Flash.get(new_socket.assigns.flash, :info) == "Correct!"
    end

    test "one bad guess", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/1")

      socket = get_socket(view)

      {:noreply, updated_socket} =
        GameSiteWeb.GuessingLive.handle_event(
          "answer",
          %{"guess" => "11", "wager" => "2"},
          socket
        )

      assert updated_socket.assigns.attempt == 2
      assert updated_socket.assigns.wager == 2
      assert updated_socket.assigns.score == 10
      assert Phoenix.Flash.get(updated_socket.assigns.flash, :error) == "Incorrect."
    end

    test "5 bad guesses", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/1")

      socket = get_socket(view)

      socket = run_five_times(socket, "2")

      assert socket.assigns.attempt == 1
      assert socket.assigns.wager == 2
      assert socket.assigns.score == 8
      assert Phoenix.Flash.get(socket.assigns.flash, :error) == "Out of Guesses."
    end

    test "reset on 5 bad guesses and full wager", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user)

      {:ok, view, _html} = live(conn, ~p"/1")

      socket = get_socket(view)

      socket = run_five_times(socket, "10")

      assert socket.assigns.attempt == 1
      assert socket.assigns.score == 10
      assert socket.assigns.wager == 1
      assert Phoenix.Flash.get(socket.assigns.flash, :error) == "Out of Points, resetting."
    end

    test "wager is set to the min of wager and score", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user)

      {:ok, view, _html} = live(conn, ~p"/1")

      socket = get_socket(view)

      socket = run_five_times(socket, "6")

      assert socket.assigns.wager == 4
      assert socket.assigns.score == 4
      assert Phoenix.Flash.get(socket.assigns.flash, :error) == "Out of Guesses."
    end

    test "exit after a correct answer", %{conn: conn, user: user, game: game} do
      conn =
        conn
        |> log_in_user(user)

      {:ok, view, _html} = live(conn, ~p"/1")

      socket = get_socket(view)
      answer = socket.assigns.answer

      {:noreply, updated_socket} =
        GameSiteWeb.GuessingLive.handle_event(
          "answer",
          %{"guess" => to_string(answer), "wager" => "2"},
          socket
        )

      assert updated_socket.assigns.score == 12
      assert updated_socket.assigns.wager == 2
      assert updated_socket.assigns.attempt == 1

      {:noreply, updated_socket} =
        GameSiteWeb.GuessingLive.handle_event(
          "exit",
          %{"user_id" => user.id, "score" => updated_socket.assigns.highest_score, "game_id" => game.id},
          updated_socket
        )


        # assert redirected_to(conn) == ~p"/scores"

        assert Phoenix.Flash.get(updated_socket.assigns.flash, :info) == "Score created successfully"
    end
  end
end
