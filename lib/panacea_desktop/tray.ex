defmodule PanaceaDesktop.Tray do
  @moduledoc """
    Menu that is shown when a user click on the taskbar icon
  """
  import PanaceaWeb.Gettext
  use Desktop.Menu

  def mount(menu) do
    {:ok, menu}
  end

  def handle_event("quit", menu) do
    Desktop.Window.quit()
    {:noreply, menu}
  end

  def handle_event("toggle", menu) do
    Desktop.Window.show(PanaceaDesktop)
    {:noreply, menu}
  end

  def handle_info(:changed, menu) do
    {:noreply, menu}
  end
end
