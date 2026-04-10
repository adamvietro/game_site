defmodule GameSiteWeb.Plugs.EnsureGuestId do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    if get_session(conn, :guest_id) do
      conn
    else
      put_session(conn, :guest_id, System.unique_integer([:positive]))
    end
  end
end
