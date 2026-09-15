defmodule GameSiteWeb.SitemapController do
  use GameSiteWeb, :controller

  alias GameSite.Pento.Board

  @doc """
  Renders a sitemap.xml listing the public, unauthenticated pages: home, scores,
  each single/multiplayer game, and every Pento puzzle.
  """
  def index(conn, _params) do
    xml = render_sitemap()

    conn
    |> put_resp_content_type("application/xml")
    |> send_resp(200, xml)
  end

  defp render_sitemap do
    base_url = GameSiteWeb.Endpoint.url()

    static_paths = [
      ~p"/",
      ~p"/scores",
      ~p"/guessing",
      ~p"/math",
      ~p"/rock-paper-scissors",
      ~p"/wordle",
      ~p"/poker",
      ~p"/pento_choice",
      ~p"/multi-poker",
      ~p"/daily-wordle"
    ]

    pento_paths = Enum.map(Board.puzzles(), fn puzzle -> ~p"/pento/#{puzzle}" end)

    urls =
      (static_paths ++ pento_paths)
      |> Enum.map_join("\n", &url_entry(base_url <> &1))

    """
    <?xml version="1.0" encoding="UTF-8"?>
    <urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
    #{urls}
    </urlset>
    """
    |> String.trim()
  end

  defp url_entry(loc) do
    """
      <url>
        <loc>#{loc}</loc>
      </url>
    """
    |> String.trim_trailing()
  end
end
