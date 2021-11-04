defmodule PanaceaDesktop.Tray do
  @moduledoc """
    Menu that is shown when a user click on the taskbar icon
  """
  import PanaceaWeb.Gettext
  use Desktop.Menu

  def mount(menu) do
    IO.puts("\n\n----------------------\nMounting Tray\n----------------------\n\n")
    {:ok, menu}
  end

  def handle_event("quit", menu) do
    Desktop.Window.quit()
    {:noreply, menu}
  end

  def handle_info(:changed, menu) do
    IO.puts("Tray - :changed")
    {:noreplay, menu}
  end
end
