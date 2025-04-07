defmodule GameSite.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      GameSiteWeb.Telemetry,
      GameSite.Repo,
      {DNSCluster, query: Application.get_env(:game_site, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: GameSite.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: GameSite.Finch},
      # Start a worker by calling: GameSite.Worker.start_link(arg)
      # {GameSite.Worker, arg},
      # Start to serve requests, typically the last entry
      GameSiteWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: GameSite.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    GameSiteWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
