import Config

# Configures the endpoint
config :panacea, PanaceaWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 0],
  secret_key_base: "tcJeZ9fH1+a6BBPmuXef5ZAJaPHL7jBvBwSXZC1Cc97doKD8NKgGrUybArfF9IUo",
  render_errors: [view: PanaceaWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Panacea.PubSub,
  live_view: [signing_salt: "GwRRp0Jp"],
  server: true

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :surface, :components, [
  {Surface.Components.Form.ErrorTag, default_translator: {PanaceaWeb.ErrorHelpers, :translate_error}}
]

# Confgi ESBuild

config :esbuild,
  version: "0.12.18",
  default: [
    args: ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
