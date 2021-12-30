defmodule PanaceaDesktop.Menubar do
  @moduledoc """
    Menubar that is shown as part of the main Window on Windows/Linux. In
    MacOS this Menubar appears at the very top of the screen.
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

  def handle_info(:changed, menu) do
    {:noreply, menu}
  end
end
