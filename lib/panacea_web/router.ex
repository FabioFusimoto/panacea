defmodule PanaceaWeb.Router do
  use PanaceaWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {PanaceaWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PanaceaWeb do
    pipe_through :browser

    live "/", WelcomeLive, :index

    live "/arduino", ArduinoLive, :index

    live "/png", PngLive, :index

    live "/snake", SnakeLive, :index

    live "/soundwave", SoundwaveLive, :index

    live "/backlighting", BacklightingLive, :index

    live "/demo", Demo
  end

  # Other scopes may use custom stacks.
  # scope "/api", PanaceaWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: PanaceaWeb.Telemetry
    end
  end
end
