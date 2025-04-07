defmodule GameSite.Repo do
  use Ecto.Repo,
    otp_app: :game_site,
    adapter: Ecto.Adapters.Postgres
end
