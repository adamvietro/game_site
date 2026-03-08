defmodule GameSiteWeb.LoginHelpers do
  def logged_in?(assigns) do
    Map.has_key?(assigns, :current_user)
  end
end
