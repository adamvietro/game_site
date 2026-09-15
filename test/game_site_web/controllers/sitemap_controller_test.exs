defmodule GameSiteWeb.SitemapControllerTest do
  use GameSiteWeb.ConnCase

  alias GameSite.Pento.Board

  test "GET /sitemap.xml lists the public game routes and every Pento puzzle", %{conn: conn} do
    conn = get(conn, ~p"/sitemap.xml")

    assert [content_type] = get_resp_header(conn, "content-type")
    assert content_type =~ "application/xml"

    body = response(conn, 200)
    assert body =~ "<urlset"
    assert body =~ ~p"/"
    assert body =~ ~p"/scores"
    assert body =~ ~p"/wordle"
    assert body =~ ~p"/poker"
    assert body =~ ~p"/pento_choice"
    assert body =~ ~p"/multi-poker"
    assert body =~ ~p"/daily-wordle"

    for puzzle <- Board.puzzles() do
      assert body =~ ~p"/pento/#{puzzle}"
    end
  end

  test "excludes authenticated-only routes", %{conn: conn} do
    body = response(get(conn, ~p"/sitemap.xml"), 200)

    refute body =~ "/games"
    refute body =~ "/daily-wordle/play"
    refute body =~ "/daily-wordle/archive"
  end
end
