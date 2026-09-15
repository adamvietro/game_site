defmodule GameSiteWeb.PageControllerTest do
  use GameSiteWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Welcome to my game site"
  end

  test "GET / includes the site-wide social preview defaults", %{conn: conn} do
    response = get(conn, ~p"/") |> html_response(200)

    assert response =~ ~s(property="og:title" content="GameSite")
    assert response =~ ~s(property="og:type" content="website")
    assert response =~ ~s(property="og:url" content="https://game.adamsites.com/")
    assert response =~ ~s(name="twitter:title" content="GameSite")
    # No meta_image assign is set by default, so no image tags (and no
    # broken-image reference) should be rendered.
    refute response =~ "og:image"
    refute response =~ "twitter:image"
    assert response =~ ~s(name="twitter:card" content="summary")
  end
end
