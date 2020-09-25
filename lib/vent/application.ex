defmodule Vent.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Vent.Repo,
      # Start the Telemetry supervisor
      VentWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Vent.PubSub},
      Vent.ChatPresence,
      # Start the Endpoint (http/https)
      VentWeb.Endpoint,
      Vent.ChatSupervisor
      # Start a worker by calling: Vent.Worker.start_link(arg)
      # {Vent.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Vent.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    VentWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
