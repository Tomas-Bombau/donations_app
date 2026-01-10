defmodule AppDonation.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AppDonationWeb.Telemetry,
      AppDonation.Repo,
      {DNSCluster, query: Application.get_env(:app_donation, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: AppDonation.PubSub},
      # Start a worker by calling: AppDonation.Worker.start_link(arg)
      # {AppDonation.Worker, arg},
      # Start to serve requests, typically the last entry
      AppDonationWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AppDonation.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AppDonationWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
