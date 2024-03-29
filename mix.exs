defmodule Panacea.MixProject do
  use Mix.Project

  def project do
    [
      app: :panacea,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix] ++ Mix.compilers() ++ [:surface],
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Panacea.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.q
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.6.15"},
      {:phoenix_live_view, "~> 0.18.3"},
      {:floki, ">= 0.30.0", only: :test},
      {:phoenix_html, "~> 3.2.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_dashboard, "~> 0.7"},
      {:telemetry_metrics, "~> 0.6.1"},
      {:telemetry_poller, "~> 1.0.0"},
      {:gettext, "~> 0.11"},
      {:jason, "~> 1.0"},
      {:plug_cowboy, "~> 2.0"},
      {:circuits_uart, "~> 1.4.3"},
      {:imagineer, "~> 0.3.3"},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false},
      {:esbuild, "~> 0.2", runtime: Mix.env() == :dev},
      {:surface, "~> 0.9.0"},
      {:surface_formatter, "~> 0.7.5"},
      {:desktop, github: "elixir-desktop/desktop", tag: "v1.3.3"},
      {:erlport, "~> 0.10.1"},
      {:poolboy, "~> 1.5"},
      {:websockex, "~> 0.4.3"},
      {:color_utils, "0.2.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "cmd npm install --prefix assets"],
      "assets.deploy": ["phx.digest.clean --all", "esbuild default --minify", "phx.digest"]
    ]
  end
end
