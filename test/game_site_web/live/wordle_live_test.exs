defmodule GameSiteWeb.WordleLiveTest do
  use GameSiteWeb.ConnCase

  import Phoenix.LiveViewTest
  import GameSite.GamesFixtures
  import GameSite.AccountsFixtures

  defp log_in_and_socket(conn, user) do
    conn =
      conn
      |> log_in_user(user)

    {:ok, view, _html} = live(conn, ~p"/4")

    state = :sys.get_state(view.pid)
    socket = state.socket

    [conn, socket]
  end

  describe "Wordle" do
    setup do
      user = user_fixture()
      game = game_fixture(%{game_id: 4})

      %{user: user, game: game}
    end

    test "access route", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user)

      {:ok, _view, html} = live(conn, ~p"/4")

      assert html =~ "Wordle"
    end

    test "good guess",%{conn: conn, user: user} do

    end

    test "bad guess", %{conn: conn, user: user} do

    end

    test "all yellow", %{conn: conn, user: user} do

    end

    test "all gray", %{conn: conn, user: user} do

    end

    test "2 good guesses", %{conn: conn, user: user} do

    end

    test "exit after a good guess", %{conn: conn, user: user} do

    end
  end

end
