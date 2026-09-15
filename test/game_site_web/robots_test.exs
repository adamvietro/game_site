defmodule GameSiteWeb.RobotsTest do
  use GameSiteWeb.ConnCase

  test "GET /robots.txt points crawlers at the sitemap and disallows auth-gated sections", %{
    conn: conn
  } do
    conn = get(conn, "/robots.txt")

    body = response(conn, 200)
    assert body =~ "Sitemap: https://game.adamsites.com/sitemap.xml"
    assert body =~ "Disallow: /dev/"
    assert body =~ "Disallow: /users/"
    assert body =~ "Disallow: /games"
  end
end
