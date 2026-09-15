defmodule GameSiteWeb.ErrorHTMLTest do
  use GameSiteWeb.ConnCase, async: true

  # Bring render_to_string/4 for testing custom views
  import Phoenix.Template

  test "renders 404.html" do
    html = render_to_string(GameSiteWeb.ErrorHTML, "404", "html", [])
    assert html =~ "404"
    assert html =~ "page not found"
    assert html =~ ~s(href="/")
  end

  test "renders 500.html" do
    html = render_to_string(GameSiteWeb.ErrorHTML, "500", "html", [])
    assert html =~ "500"
    assert html =~ "internal server error"
    assert html =~ ~s(href="/")
  end
end
