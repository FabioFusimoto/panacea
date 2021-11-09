defmodule Panacea.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  alias Panacea.DesktopConfig

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
      Panacea.Worker,

      # Python gateway handler
      Panacea.PythonGateway
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Panacea.Supervisor]
    {:ok, sup} = Supervisor.start_link(children, opts)

    # For Desktop app
    Desktop.identify_default_locale(PanaceaWeb.Gettext)
    {:ok, _} = Supervisor.start_child(sup, DesktopConfig.options())
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    PanaceaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
