defmodule PanaceaWeb.WelcomeLive do
  use Surface.LiveView
  import PanaceaWeb.Gettext
  alias Desktop.Window

  alias PanaceaWeb.Components.Hero

  def render(assigns) do
    ~F"""
    <div>
      <Hero name="Panacea" subtitle="LED Arduino Control with Elixir" color="info"/>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
