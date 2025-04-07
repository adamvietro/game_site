defmodule GameSiteWeb.ScoreLiveTest do
  use GameSiteWeb.ConnCase

  import Phoenix.LiveViewTest
  import GameSite.ScoresFixtures

  @create_attrs %{score: 42}
  @update_attrs %{score: 43}
  @invalid_attrs %{score: nil}

  defp create_score(_) do
    score = score_fixture()
    %{score: score}
  end

  describe "Index" do
    setup [:create_score]

    test "lists all scores", %{conn: conn} do
      {:ok, _index_live, html} = live(conn, ~p"/scores")

      assert html =~ "Listing Scores"
    end

    test "saves new score", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/scores")

      assert index_live |> element("a", "New Score") |> render_click() =~
               "New Score"

      assert_patch(index_live, ~p"/scores/new")

      assert index_live
             |> form("#score-form", score: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#score-form", score: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/scores")

      html = render(index_live)
      assert html =~ "Score created successfully"
    end

    test "updates score in listing", %{conn: conn, score: score} do
      {:ok, index_live, _html} = live(conn, ~p"/scores")

      assert index_live |> element("#scores-#{score.id} a", "Edit") |> render_click() =~
               "Edit Score"

      assert_patch(index_live, ~p"/scores/#{score}/edit")

      assert index_live
             |> form("#score-form", score: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#score-form", score: @update_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/scores")

      html = render(index_live)
      assert html =~ "Score updated successfully"
    end

    test "deletes score in listing", %{conn: conn, score: score} do
      {:ok, index_live, _html} = live(conn, ~p"/scores")

      assert index_live |> element("#scores-#{score.id} a", "Delete") |> render_click()
      refute has_element?(index_live, "#scores-#{score.id}")
    end
  end

  describe "Show" do
    setup [:create_score]

    test "displays score", %{conn: conn, score: score} do
      {:ok, _show_live, html} = live(conn, ~p"/scores/#{score}")

      assert html =~ "Show Score"
    end

    test "updates score within modal", %{conn: conn, score: score} do
      {:ok, show_live, _html} = live(conn, ~p"/scores/#{score}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Score"

      assert_patch(show_live, ~p"/scores/#{score}/show/edit")

      assert show_live
             |> form("#score-form", score: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#score-form", score: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/scores/#{score}")

      html = render(show_live)
      assert html =~ "Score updated successfully"
    end
  end
end
