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

    test "access route", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user)

      {:ok, _view, html} = live(conn, ~p"/1")

      assert html =~ "Guessing Game"
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
      assert Phoenix.Flash.get(updated_socket.assigns.flash, :info) == "Incorrect."
    end

    test "5 bad guesses", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/1")

      socket = get_socket(view)

      socket =
        Enum.reduce(1..5, socket, fn _n, acc_socket ->
          {:noreply, new_socket} =
            GameSiteWeb.GuessingLive.handle_event(
              "answer",
              %{"guess" => "11", "wager" => "2"},
              acc_socket
            )

          new_socket
        end)

      assert socket.assigns.attempt == 1
      assert socket.assigns.wager == 2
      assert socket.assigns.score == 8
      assert Phoenix.Flash.get(socket.assigns.flash, :info) == "Out of Guesses."
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

    test "reset on 5 bad guesses and full wager", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user)

      {:ok, view, _html} = live(conn, ~p"/1")

      socket = get_socket(view)

      socket =
        Enum.reduce(1..5, socket, fn _n, acc_socket ->
          {:noreply, new_socket} =
            GameSiteWeb.GuessingLive.handle_event(
              "answer",
              %{"guess" => "11", "wager" => "10"},
              acc_socket
            )

          new_socket
        end)

      assert socket.assigns.attempt == 1
      assert socket.assigns.score == 10
      assert socket.assigns.wager == 1
      assert Phoenix.Flash.get(socket.assigns.flash, :info) == "Out of Points, resetting."
    end
  end
end
