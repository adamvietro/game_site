defmodule GameSiteWeb.Plugs.StoreCurrentPath do
  import Plug.Conn
  import Phoenix.Controller, only: [current_path: 1]

  def init(opts), do: opts

  def call(conn, _opts) do
    if conn.method == "GET" &&
         !String.starts_with?(conn.request_path, "/users") do
      put_session(conn, :user_return_to, current_path(conn))
    else
      conn
    end
  end
end
