defmodule PanaceaWeb.SnakeLive do
  use PanaceaWeb, :live_view
  alias Panacea.Snake.Game, as: Game
  alias Panacea.Snake.Controls, as: Controls

  def mount(_params, _assigns, socket) do
    {:ok, assign(socket, started: false)}
  end

  def handle_event("start_game", _value, socket) do
    Game.start()
    {:noreply, assign(socket, started: true)}
  end

  def handle_event("stop_game", _value, socket) do
    Game.stop()
    {:noreply, assign(socket, started: false)}
  end

  def handle_event("handle_key", %{"key" => key}, socket) do
    case key do
      k when k in ["w", "W"] ->
        Controls.up()
      k when k in ["s", "S"] ->
        Controls.down()
      k when k in ["a", "A"] ->
        Controls.left()
      k when k in ["d", "D"] ->
        Controls.right()
      _ ->
        nil
    end

    {:noreply, socket}
  end
end
