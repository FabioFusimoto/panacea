defmodule PanaceaWeb.WelcomeLive do
  use Surface.LiveView
  import PanaceaWeb.Gettext
  alias Desktop.Window

  alias PanaceaWeb.Components.Hero

  def render(assigns) do
    ~F"""
    <div>
      <Hero name="Panacea" subtitle="LED Arduino Control with Elixir" color="info"/>
      <button phx-click="display_notification">Display notification</button>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_event("display_notification", _value, socket) do
    Window.show_notification(
      PanaceaDesktop,
      gettext("A notification from Panacea")
    )

    {:noreply, socket}
  end
end
