defmodule Panacea.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      PanaceaWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Panacea.PubSub},
      # Start the Endpoint (http/https)
      PanaceaWeb.Endpoint,
      # Open the serial connection
      Panacea.Serial,
      # Start the command handler ("background" worker)
      Panacea.Worker
      # Start a worker by calling: Panacea.Worker.start_link(arg)
      # {Panacea.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Panacea.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    PanaceaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
