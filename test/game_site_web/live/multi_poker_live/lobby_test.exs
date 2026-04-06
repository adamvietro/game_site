defmodule GameSiteWeb.MultiPokerLive.LobbyTest do
  use ExUnit.Case, async: true

  alias GameSiteWeb.MultiPokerLive.Lobby
  alias Phoenix.LiveView.Socket

  defp socket_with_assigns(assigns \\ %{}) do
    %Socket{assigns: Map.put(assigns, :__changed__, %{})}
  end

  test "set_current_viewer_id/2 sets signed in user viewer id" do
    socket = socket_with_assigns(%{current_user: %{id: 123}})

    result = Lobby.set_current_viewer_id(socket, %{})

    assert result.assigns.current_viewer_id == "user:123"
  end

  test "set_current_viewer_id/2 sets not_signed_in when there is no current user" do
    socket = socket_with_assigns(%{current_user: nil})

    result = Lobby.set_current_viewer_id(socket, %{})

    assert result.assigns.current_viewer_id == :not_signed_in
  end

  test "set_current_viewer_id/2 sets not_signed_in when current_user assign is missing" do
    socket = socket_with_assigns()

    result = Lobby.set_current_viewer_id(socket, %{})

    assert result.assigns.current_viewer_id == :not_signed_in
  end
end
