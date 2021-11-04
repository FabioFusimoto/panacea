defmodule Panacea.DesktopConfig do
  @moduledoc """
  `Desktop.Window` configuration options
  """

  @app Mix.Project.config()[:app]

  #############
  # Interface #
  #############
  def options() do
    {
      Desktop.Window,
      [
        app: @app,
        id: PanaceaDesktop,
        title: "Panacea",
        size: {800, 600},
        icon: "icon.ico",
        # menubar: PanaceaDesktop.Menubar,
        icon_menu: PanaceaDesktop.Tray,
        url: &PanaceaWeb.Endpoint.url/0
      ]
    }
  end
end
