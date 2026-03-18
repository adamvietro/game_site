defmodule GameSiteWeb.GameLiveTest do
  use GameSiteWeb.ConnCase

  import Phoenix.LiveViewTest
  import GameSite.GamesFixtures
  import GameSite.AccountsFixtures

  @create_attrs %{name: "some name"}
  @invalid_attrs %{name: nil}

  defp create_game(_) do
    user = user_fixture()
    game = game_fixture(@create_attrs)
    %{game: game, user: user}
  end

  describe "Index" do
    setup [:create_game]

    test "lists all games", %{conn: conn, game: game, user: user} do
      conn =
        conn
        |> log_in_user(user)

      {:ok, _index_live, html} = live(conn, ~p"/games")

      assert html =~ "Listing Games"
      assert html =~ game.name
    end

    test "saves new game", %{conn: conn, game: _game, user: user} do
      conn =
        conn
        |> log_in_user(user)

      {:ok, index_live, _html} = live(conn, ~p"/games/new")

      # assert index_live |> element("a", "New Game") |> render_click() =~
      #          "New Game"

      # assert_patch(index_live, ~p"/games/new")

      assert index_live
             |> form("#game-form", game: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#game-form", game: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/games")

      html = render(index_live)
      assert html =~ "Game created successfully"
      assert html =~ "some name"
    end

    # test "updates game in listing", %{conn: conn, game: game} do
    #   {:ok, index_live, _html} = live(conn, ~p"/games")

    #   assert index_live |> element("#games-#{game.id} a", "Edit") |> render_click() =~
    #            "Edit Game"

    #   assert_patch(index_live, ~p"/games/#{game}/edit")

    #   assert index_live
    #          |> form("#game-form", game: @invalid_attrs)
    #          |> render_change() =~ "can&#39;t be blank"

    #   assert index_live
    #          |> form("#game-form", game: @update_attrs)
    #          |> render_submit()

    #   assert_patch(index_live, ~p"/games")

    #   html = render(index_live)
    #   assert html =~ "Game updated successfully"
    #   assert html =~ "some updated name"
    # end

    # test "deletes game in listing", %{conn: conn, game: game, user: user} do
    #   conn =
    #     conn
    #     |> log_in_user(user)
    #   {:ok, index_live, _html} = live(conn, ~p"/games")

    #   assert index_live |> element("#games-#{game.id} a", "Delete") |> render_click()
    #   refute has_element?(index_live, "#games-#{game.id}")
    # end
  end

  # describe "Show" do
  #   setup [:create_game]

  #   test "displays game", %{conn: conn, game: game} do
  #     {:ok, _show_live, html} = live(conn, ~p"/games/#{game}")

  #     assert html =~ "Show Game"
  #     assert html =~ game.name
  #   end

  #   test "updates game within modal", %{conn: conn, game: game} do
  #     {:ok, show_live, _html} = live(conn, ~p"/games/#{game}")

  #     assert show_live |> element("a", "Edit") |> render_click() =~
  #              "Edit Game"

  #     assert_patch(show_live, ~p"/games/#{game}/show/edit")

  #     assert show_live
  #            |> form("#game-form", game: @invalid_attrs)
  #            |> render_change() =~ "can&#39;t be blank"

  #     assert show_live
  #            |> form("#game-form", game: @update_attrs)
  #            |> render_submit()

  #     assert_patch(show_live, ~p"/games/#{game}")

  #     html = render(show_live)
  #     assert html =~ "Game updated successfully"
  #     assert html =~ "some updated name"
  #   end
end
