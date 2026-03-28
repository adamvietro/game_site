defmodule GameSiteWeb.MultiPokerLive do
  use GameSiteWeb, :live_view

  def render(assigns) do
    ~H"""
    The Games will go here.
    """
  end

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :room, nil)}
  end
end
